import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
import torch
import torch.nn as nn
import matplotlib.pyplot as plt
import torch.nn.init as init
import time
import numpy as np
import torch.nn.functional as F
import subprocess
from ipywidgets import interactive, widgets
import shutil
from tqdm import tqdm

# For 3D Mesh
#import mcubes  # Per marching cubes
from skimage import measure  # Alternativa per marching cubes
from scipy.ndimage import gaussian_filter
#import open3d as o3d  # Per visualizzazione e salvataggio

img_folder = 'img'
# Se la cartella esiste, cancellala completamente
if os.path.exists(img_folder):
    shutil.rmtree(img_folder)
# Ricrea la cartella vuota
os.makedirs(img_folder, exist_ok=True)

# Caricamento e pre-elaborazione dati
#if not os.path.exists('tiny_nerf_data.npz'):
#    url = "http://cseweb.ucsd.edu/~viscomp/projects/LF/papers/ECCV20/nerf/tiny_nerf_data.npz"
#    subprocess.run(["wget", url])

'''
Il positional encoding è un metodo di encoding che permette di aumentare il livello di dettaglio dell'immagine, creandone varie frequenze
Prende in input un tensore x ed un parametro L che definisce quante frequenze utilizzare.
Crea quindi le frequenze, ed alla fine concatena tutti questi tensori insime lungo l'ultima dimensione.
Questo tipo di encoding è utile perchè:
    1. trasforma i valori scalari in rappresentazioni ad alta dimensione
    2. cattura informazioni a diverse frequenze / scale
    3. permette alle reti neurali di apprendere meglio relazioni che dipendono dalla posizione o da valori continui
'''
def encoding(x, L=10):
  res = [x]
  for i in range(L):
    for fn in [torch.sin, torch.cos]:
      res.append(fn(2 ** i * torch.pi * x))
  return torch.cat(res,dim=-1)

x = torch.Tensor([3.1,5.6,7.3])
y = encoding(x,L=4)
y.shape

'''
Qui viene implementato il modello NeRF. (ricordiamo che NeRF mappa coordinate spaziali 5d, 3 di posizione e 2 di vista 2D)
'''
# Implementazione del modello NeRF
class NeRF(nn.Module):
    '''
        Inizializzazione del modello, vengono passate le dimensioni dell'initial state (63 che sono quelle che ricaviamo dal positional encoding)
        Vengono anche passate le dimensioni del numero di neuroni nei layer centrali (256 in ingresso)
    '''
    def __init__(self, pos_enc_dim=63, view_enc_dim=27, hidden=256) -> None:
        super().__init__()

        '''
            Crea il primo layer, neruoni iniziali che arrivano dal positional encoding e vengono trasformati in 256 di output
            Viene utilizzata la ReLU come funzione di attivazione
        '''
        self.linear1 = nn.Sequential(nn.Linear(pos_enc_dim,hidden),nn.ReLU())
        # Applica una trasformazione lineare ai dati di input con attivazione ReLU

        '''
            Abbiamo 4 blocchi sequenziali, ciascuno formato da un layer linear al cui output viene applicata la ReLU
            I neuroni rimangono sempre 256
        '''
        self.pre_skip_linear = nn.Sequential()
        for _ in range(4):
            self.pre_skip_linear.append(nn.Linear(hidden,hidden))
            self.pre_skip_linear.append(nn.ReLU())

        '''
            In questo caso prendo in ingresso non solo l'output dei layer precedenti ma di nuovo anche i dati elaborati dal positional encoding.
            Questo permette all'informazione di saltare alcuni layer, preservando così l'informazione ad alta frequenza che potrebbe perdersi nei layer profondi
        '''
        self.linear_skip = nn.Sequential(nn.Linear(pos_enc_dim+hidden,hidden),nn.ReLU())

        '''
            2 ulteriori blocchi funzionanti come il pre_skip
        '''
        self.post_skip_linear = nn.Sequential()
        for _ in range(2):
            self.post_skip_linear.append(nn.Linear(hidden,hidden))
            self.post_skip_linear.append(nn.ReLU())

        '''
            Ora cerco di trasformare tutte le feature in un singolo valore di densità, la ReLU mi garantisce che le densità non siano mai negative
        '''
        self.density_layer = nn.Sequential(nn.Linear(hidden,1),nn.ReLU())
        # Stima la densità (cioè la presenza di materia in un punto 3D)

        self.linear2 = nn.Linear(hidden,hidden)

        '''
            Predico il colore, la sigmoide mi permette di mantenere i valorei tra 0 ed 1
        '''
        self.color_linear1 = nn.Sequential(nn.Linear(hidden+view_enc_dim,hidden//2),nn.ReLU())
        self.color_linear2 = nn.Sequential(nn.Linear(hidden//2,3),nn.Sigmoid())
        # Predice il colore (RGB) in un punto

    '''
        Definisce il flusso di elaborazione dei dati attraverso la rete neurale
        Quindi come i dati in input fluiscono attraverso i vari layer del modello
    '''
    def forward(self, input):
        # Divido l'input in coordinate spaziali e di vista
        positions = input[...,:3]
        view_dirs = input[...,3:]

        # Encode -> positional encoding ai dati in ingresso. Uso frequenza più alte per le posizioni rispetto alle direzioni
        pos_enc = encoding(positions,L=10)
        view_enc = encoding(view_dirs,L=4)

        x = self.linear1(pos_enc)
        x = self.pre_skip_linear(x)

        # Skip connection
        x = torch.cat([x,pos_enc],dim=-1)
        x = self.linear_skip(x)

        x = self.post_skip_linear(x)

        # Density
        sigma = self.density_layer(x)

        x = self.linear2(x)

        # View Encoding
        x = torch.cat([x,view_enc],dim=-1)
        x = self.color_linear1(x)

        # Color Prediction
        rgb = self.color_linear2(x)

        # Applica trasformazioni ai dati per apprendere la rappresentazione 3D

        # Restituisce densità e colore per ogni punto

        return torch.cat([sigma,rgb],dim=-1)

'''
    La funzione genera un raggio per ogni pixel dell'immagine
    E' utile per generare nuove viste 3D
'''
def get_rays(H, W, focal, c2w):
    """
        Generate rays for a given camera configuration.

        Args:
            H: Image height.
            W: Image width.
            focal: Focal length.
            c2w: Camera-to-world transformation matrix (4x4).

        Returns:
            rays_o: Ray origins (H*W, 3).
            rays_d: Ray directions (H*W, 3).
    """
    device = c2w.device  # Get the device of c2w
    focal = torch.from_numpy(focal).to(device)
    # print(type(H), type(W), type(focal), type(c2w))

    i, j = torch.meshgrid(
        torch.arange(W, dtype=torch.float32, device=device),
        torch.arange(H, dtype=torch.float32, device=device),
        indexing='xy'
    )
    dirs = torch.stack(
        [(i - W * .5) / focal, -(j - H * .5) / focal, -torch.ones_like(i, device = device)], -1
    )

    rays_d = torch.sum(dirs[..., None, :] * c2w[:3, :3], -1)
    rays_d = rays_d.view(-1, 3)
    rays_o = c2w[:3, -1].expand(rays_d.shape)

    return rays_o, rays_d

# Rendering della scena
def render_rays(network_fn, rays_o, rays_d, near, far, N_samples, device, rand=False, embed_fn=None, chunk=1024*4):
    # Usa NeRF per calcolare il colore lungo ogni raggio
    def batchify(fn, chunk):
        return lambda inputs: torch.cat([fn(inputs[i:i+chunk]) for i in range(0, inputs.shape[0], chunk)], 0)

    # Campiona punti lungo il raggio
    z_vals = torch.linspace(near, far, steps=N_samples, device=device)

    if rand:
        z_vals += torch.rand(*z_vals.shape[:-1], N_samples, device=rays_o.device) * (far - near) / N_samples

    pts = rays_o[...,None,:] + rays_d[...,None,:] * z_vals[...,:,None]
    # Genera coordinate 3D per ogni campione

    # Normalize view directions
    view_dirs = rays_d / torch.norm(rays_d, dim=-1, keepdim=True)
    view_dirs = view_dirs[..., None, :].expand(pts.shape)

    input_pts = torch.cat((pts, view_dirs), dim=-1)
    raw = batchify(network_fn, chunk)(input_pts)

    # Apply activations here instead of in network
    sigma_a = raw[...,0]  # Shape: [batch, N_samples]
    rgb = raw[...,1:]    # Shape: [batch, N_samples, 3]

    # Combina i colori dei campioni per ottenere il colore finale di ogni pixel

    # Improved volume rendering
    dists = z_vals[..., 1:] - z_vals[..., :-1]  # Shape: [batch, N_samples-1]
    dists = torch.cat([dists, torch.tensor([1e10], device=device)], -1)

    # No need to manually expand dists as broadcasting will handle it
    alpha = 1. - torch.exp(-sigma_a * dists)  # Shape: [batch, N_samples]
    alpha = alpha.unsqueeze(-1)  # Shape: [batch, N_samples, 1]

    # Computing transmittance
    ones_shape = (alpha.shape[0], 1, 1)
    T = torch.cumprod(
        torch.cat([
            torch.ones(ones_shape, device=device),
            1. - alpha + 1e-10
        ], dim=1),
        dim=1
    )[:, :-1]  # Shape: [batch, N_samples, 1]

    weights = alpha * T  # Shape: [batch, N_samples, 1]

    # Compute final colors and depths
    rgb_map = torch.sum(weights * rgb, dim=1)  # Sum along sample dimension
    depth_map = torch.sum(weights.squeeze(-1) * z_vals, dim=-1)  # Shape: [batch]
    acc_map = torch.sum(weights.squeeze(-1), dim=-1)  # Shape: [batch]

    return rgb_map, depth_map, acc_map

# Training del modello
'''
    images: Collezione di immagini della scena riprese da diverse angolazioni
    poses: Posizioni e orientamenti della camera per ogni immagine
    H, W: Altezza e larghezza delle immagini in pixel
    focal: Lunghezza focale della camera
    testpose, testimg: Posizione della camera e immagine per validazione
    device: Hardware su cui eseguire i calcoli (CPU o GPU)
'''
def train(images,poses,H,W,focal,testpose,testimg,device):

    print(f"Using device: {device}")
    # Creo un nuovo modello NeRF e lo sposto sul dispositivo specificato
    model = NeRF().to(device)

    # Definisco una funzione di errore per allenare il modello (è la mean square loss, quindi errore quadratico medio)
    criterion = nn.MSELoss(reduction='mean')
    # Adam è una tecnica che viene utilizzata per regolare il learning rate man mano che mi avvicino alla soluzione. Quindi man mano che mi muovo nella direzione del gradiente, aggiusta il learning rate
    # In particolare Adam tiene traccia anche dei gradienti precedenti e quindi fa una media dei gradienti precedenti per decidere di quanto sistemare quello attuale
    # Il parametro beta decide quanto peso dare ai gradienti precedenti (se i gradienti vanno sempre nella stessa direzione fa passi più lunghi, altrimenti diminuisce)
    optimizer = torch.optim.Adam(model.parameters(),lr=5e-4)
    # Lo scheduler agisce sopra Adam e permette di scalare i learning rate del 1% ad ogni epoca a livello globale
    scheduler = torch.optim.lr_scheduler.ExponentialLR(optimizer, gamma=0.99)
    # Quindi ricapitolando Adam assegna un learning rate dinamico a ciascun peso della rete, basandosi sui gradienti passati
    # Lo scheduler prende il learning rate base di Adam e lo moltiplica per un fattore gamma ad ogni epoca

    # Setto i parametri
    n_iter = 1000
    n_samples = 64
    i_plot = 50
    psnrs = []
    iternums = []
    t = time.time()

    # Convert data to tensors and move to device ONCE
    images_tensor = torch.from_numpy(images).float().to(device)
    poses_tensor = torch.from_numpy(poses).float().to(device)

    print("🚀 Training iniziato...")

    for i in range(n_iter):

        print(f"🟢 Iterazione {i}/{n_iter} in corso...")  # Mostra progressi

        # Seleziono i dati in maniera randomica
        img_i = np.random.randint(images.shape[0])

        target = images_tensor[img_i]  # Use the corresponding image
        pose = poses_tensor[img_i]     # Use the corresponding pose

        # Genero i raggi per descrivere la scena
        rays_o, rays_d = get_rays(H, W, focal, pose)

        optimizer.zero_grad()

        # Uso il modello attuale per prevedere i colori lungo i raggi, campionando 64 punti per raggio
        rgb, depth, acc = render_rays(model, rays_o, rays_d, near=2., far=6., N_samples=n_samples, device=device, rand=True)

        rgb = rgb.reshape(H,W,3)

        # Calcolo dell'errore
        loss = criterion(rgb, target)

        # Aggiornamento dei pesi
        loss.backward()
        # Diminuisce il learning rate
        optimizer.step()

        if (i + 1) % images_tensor.shape[0] == 0: # una volta che ho processato tutte le immagini, aggiorno con lo scheduler il learning rate. Evita di ridurre il learning rate troppo velocemente
            scheduler.step()
            print(f"Learning rate aggiornato: {optimizer.param_groups[0]['lr']:.8f}")

        # Ogni i_plot iterazioni genera un'immagine
        if i % i_plot == 0:
            print(f'Iteration: {i}, Loss: {loss.item():.6f}, Time: {(time.time() - t) / i_plot:.2f} secs per iter')
            t = time.time()

            with torch.no_grad():
                rays_o, rays_d = get_rays(H, W, focal, testpose)
                rgb, depth, acc = render_rays(model, rays_o, rays_d, near=2., far=6.,
                                           N_samples=n_samples, device=device)
                rgb = rgb.reshape(H, W, 3)
                loss = criterion(rgb, testimg)
                psnr = -10. * torch.log10(loss)

                psnrs.append(psnr.item())
                iternums.append(i)

                print("📸 Generazione immagine all'iterazione:", i)

                plt.figure(figsize=(10,4))
                plt.subplot(121)
                plt.imshow(rgb.detach().cpu().numpy())
                plt.title(f'Iteration: {i}')
                plt.subplot(122)
                plt.plot(iternums, psnrs)
                plt.title('PSNR')
                plt.savefig(f'img/nerf_output_iter_{i}.png')
                plt.close()

        print(f"🔹 Iter {i}: Loss = {loss.item():.6f}")  


    return model

data = np.load('poses_bounds_2.npz')
images = data['images']
poses = data['poses']
focal = data['focal']
H, W = images.shape[1:3]
device = "cuda"

print("Images:")
print(images.shape)
print("Poses:")
print(poses.shape)
print("Focal:")
print(focal)

dim = len(images) - 1
testimg, testpose = images[dim], poses[dim]
images = images[:dim-1,...,:3]
poses = poses[:dim-1]
#plt.imshow(testimg)
#plt.show()
device = torch.device(device)
testimg = torch.from_numpy(testimg).float().to(device)
testpose = torch.from_numpy(testpose).float().to(device)

torch.cuda.empty_cache()
torch.cuda.ipc_collect()
model = train(images,poses,H,W,focal,testpose,testimg,device)


# Render video

# Transformation matrices in PyTorch
trans_t = lambda t: torch.tensor([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, t],
    [0, 0, 0, 1]
], dtype=torch.float32)

rot_phi = lambda phi: torch.tensor([
    [1, 0, 0, 0],
    [0, torch.cos(phi), -torch.sin(phi), 0],
    [0, torch.sin(phi), torch.cos(phi), 0],
    [0, 0, 0, 1]
], dtype=torch.float32)

rot_theta = lambda th: torch.tensor([
    [torch.cos(th), 0, -torch.sin(th), 0],
    [0, 1, 0, 0],
    [torch.sin(th), 0, torch.cos(th), 0],
    [0, 0, 0, 1]
], dtype=torch.float32)

# Pose function with spherical coordinates
def pose_spherical(theta, phi, radius):
    c2w = trans_t(radius)
    c2w = torch.matmul(rot_phi(torch.Tensor([phi / 180. * np.pi])), c2w)
    c2w = torch.matmul(rot_theta(torch.Tensor([theta / 180. * np.pi])), c2w)
    c2w = torch.tensor([[-1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, 0], [0, 0, 0, 1]], dtype=torch.float32) @ c2w
    return c2w

# Function for rendering based on user input
def f(**kwargs):
    c2w = pose_spherical(**kwargs)
    rays_o, rays_d = get_rays(H, W, focal, c2w[:3, :4])  # Get rays (this is a placeholder)
    c2w, rays_o, rays_d = map(lambda t: t.to(device), (c2w, rays_o, rays_d))
    with torch.no_grad():
      rgb, depth, acc = render_rays(model, rays_o, rays_d, near=2., far=6., N_samples=64, device=device)  # Render rays
    rgb = rgb.reshape(H, W, 3).cpu().detach()
    img = torch.clamp(rgb, 0, 1).numpy()  # Clamp RGB values between 0 and 1 and convert to numpy

    plt.figure(2, figsize=(20, 6))
    plt.imshow(img)
    plt.show()

# Interactive slider setup for theta, phi, and radius
sldr = lambda v, mi, ma: widgets.FloatSlider(
    value=v,
    min=mi,
    max=ma,
    step=.01,
)

names = [
    ['theta', [100., 0., 360]],
    ['phi', [-30., -90, 0]],
    ['radius', [4., 3., 5.]],
]

interactive_plot = interactive(f, **{s[0]: sldr(*s[1]) for s in names})
output = interactive_plot.children[-1]
output.layout.height = '350px'
interactive_plot

frames = []
for th in tqdm(np.linspace(0., 360., 120, endpoint=False)):
    c2w = pose_spherical(th, -30., 4.)
    rays_o, rays_d = get_rays(H, W, focal, c2w[:3,:4])
    c2w, rays_o, rays_d = map(lambda t: t.to(device), (c2w, rays_o, rays_d))
    with torch.no_grad():
      rgb, depth, acc = render_rays(model, rays_o, rays_d, near=2., far=6., N_samples=64, device = device)
    rgb = rgb.reshape(H, W, 3)
    frames.append((255*np.clip(rgb.cpu().detach().numpy(),0,1)).astype(np.uint8))

import imageio
f = 'video.mp4'
imageio.mimwrite(f, frames, fps=30, quality=7)

from IPython.display import HTML
from base64 import b64encode
mp4 = open('video.mp4','rb').read()
data_url = "data:video/mp4;base64," + b64encode(mp4).decode()
HTML("""
<video width=400 controls autoplay loop>
      <source src="%s" type="video/mp4">
</video>
""" % data_url)

# def extract_3d_mesh(model, device, resolution=128, iso_level=25.0, bbox=2.0):
#     """
#     Esegue una scansione 3D nello spazio, valuta la densità neurale (sigma)
#     e applica marching cubes per estrarre la mesh.
#     """
#     model.eval()
#     with torch.no_grad():
#         # Generiamo un volume regolare in [-bbox, bbox]
#         xs = torch.linspace(-bbox, bbox, resolution)
#         ys = torch.linspace(-bbox, bbox, resolution)
#         zs = torch.linspace(-bbox, bbox, resolution)
#         X, Y, Z = torch.meshgrid(xs, ys, zs, indexing="ij")
#         grid_points = torch.stack([X, Y, Z], dim=-1).to(device).reshape(-1, 3)

#         sigmas = []
#         batch_size = 1024
#         # Query del modello per ogni punto
#         for i in range(0, grid_points.shape[0], batch_size):
#             pts_batch = grid_points[i : i+batch_size]
#             # Direzioni fittizie (qui non servono, ma la rete le usa)
#             dummy_dirs = torch.zeros_like(pts_batch).to(device)
#             raw = model(torch.cat([pts_batch, dummy_dirs], dim=-1))
#             σ = raw[..., 0]
#             sigmas.append(σ.detach().cpu())

#         sigmas = torch.cat(sigmas).view(resolution, resolution, resolution).numpy()

#     # Marching cubes
#     vertices, faces = mcubes.marching_cubes(sigmas, iso_level)
#     # Salvataggio .obj
#     mcubes.export_obj(vertices, faces, "extracted_mesh.obj")
#     print("Mesh 3D salvata in extracted_mesh.obj")

def extract_3d_mesh(model, device, resolution=128, iso_level=None, bbox=2.0):
    from skimage import measure
    
    model.eval()
    with torch.no_grad():
        # Genera un volume regolare in [-bbox, bbox]
        xs = torch.linspace(-bbox, bbox, resolution)
        ys = torch.linspace(-bbox, bbox, resolution)
        zs = torch.linspace(-bbox, bbox, resolution)
        X, Y, Z = torch.meshgrid(xs, ys, zs, indexing="ij") # creazione di una griglia 3D
        # La griglia viene rimodellata in un array di punti 3D
        # Ogni punto ha coordinate (x, y, z)
        grid_points = torch.stack([X, Y, Z], dim=-1).to(device).reshape(-1, 3)

        print(f"[DEBUG] Grid points shape: {grid_points.shape}")

        # Query del modello per ogni punto
        # La rete neurale viene interrogata per ogni punto nella griglia
        sigmas = []
        batch_size = 1024
        for i in range(0, grid_points.shape[0], batch_size):
            pts_batch = grid_points[i : i+batch_size]
            dummy_dirs = torch.zeros_like(pts_batch).to(device)
            print(f"[DEBUG] Processing points batch {i} -> {i+batch_size}")
            # Il modello viene interrogato con le coordinate del punto e le direzioni fittizie
            # Le direzioni fittizie non influenzano il risultato, ma sono necessarie per la rete
            # La rete neurale restituisce un valore di densità (sigma) per ogni punto
            raw = model(torch.cat([pts_batch, dummy_dirs], dim=-1))
            # Prendiamo solo la densità
            sigma = raw[..., 0]

            print(f"[DEBUG] Sigma batch mean: {sigma.mean().item():.4f}, min: {sigma.min().item():.4f}, max: {sigma.max().item():.4f}")
            sigmas.append(sigma.cpu())

        # Concatenazione dei risultati
        # La densità viene rimodellata in una matrice 3D
        # Ogni voxel della matrice rappresenta la densità in quel punto dello spazio
        # La matrice ha dimensioni (resolution, resolution, resolution)
        # La densità viene convertita in un array NumPy
        sigmas = torch.cat(sigmas).reshape(resolution, resolution, resolution).numpy()
        print("[DEBUG] Final sigmas shape:", sigmas.shape)
    '''    
        # Rimuovo i valori di densità sotto una certa soglia z, così da eliminare il piano che non mi interessa
        z_threshold = 0.0
        z_vals = np.linspace(-bbox, bbox, resolution)

        # z_vals ha dimensione [resolution], creiamo una griglia 3D che corrisponda a 'sigmas'
        Z_3D = z_vals.reshape(1, 1, resolution)            # forma (1, 1, resolution)
        Z_3D = np.broadcast_to(Z_3D, sigmas.shape)         # forma (resolution, resolution, resolution)

        # Ora poniamo a zero tutte le sigma al di sotto di z_threshold
        sigmas[Z_3D < z_threshold] = 0
    '''
    sigmas = gaussian_filter(sigmas, sigma=0.4)  # Aumentare sigma per un maggiore smoothing
    sigma_min, sigma_max = sigmas.min(), sigmas.max()
    #if iso_level is None:
    #    iso_level = 0.5 * (sigma_max - sigma_min)
    iso_level = np.percentile(sigmas, 65)

    print(f"Sigma range: [{sigma_min:.4f}, {sigma_max:.4f}] - iso_level={iso_level:.2f}")
    # Marching cubes
    # La funzione marching_cubes estrae una mesh 3D dalla matrice di densità
    verts, faces, _, _ = measure.marching_cubes(
        sigmas, level=iso_level, spacing=(2*bbox/resolution,)*3
    )
    with open("extracted_mesh.obj", "w") as f:
        for v in verts:
            f.write(f"v {v[0]} {v[1]} {v[2]}\n")
        for face in faces:
            f.write(f"f {face[0]+1} {face[1]+1} {face[2]+1}\n")

    print("[DEBUG] Number of vertices:", len(verts))
    print("[DEBUG] Number of faces:", len(faces))
    print("Mesh 3D salvata in extracted_mesh.obj")


def extract_3d_mesh_with_color(model, device, resolution=128, bbox=2.0):
    model.eval()
    with torch.no_grad():
        # Genera griglia
        xs = torch.linspace(-bbox, bbox, resolution)
        ys = torch.linspace(-bbox, bbox, resolution)
        zs = torch.linspace(-bbox, bbox, resolution)
        X, Y, Z = torch.meshgrid(xs, ys, zs, indexing="ij")
        grid_points = torch.stack([X, Y, Z], dim=-1).to(device).reshape(-1, 3)

        sigmas = []
        batch_size = 1024
        for i in range(0, grid_points.shape[0], batch_size):
            pts_batch = grid_points[i : i+batch_size]
            dummy_dirs = torch.zeros_like(pts_batch).to(device)  # direzioni nulle
            raw = model(torch.cat([pts_batch, dummy_dirs], dim=-1))
            sigmas.append(raw[..., 0].cpu())

        sigmas = torch.cat(sigmas).reshape(resolution, resolution, resolution).numpy()

    # Smooth
    sigmas = gaussian_filter(sigmas, sigma=1.0)
    iso_level = np.percentile(sigmas, 60)

    # Marching cubes
    verts, faces, _, _ = measure.marching_cubes(
        sigmas, level=iso_level, spacing=(2*bbox/resolution,)*3
    )

    # Calcola il colore per i vertici
    # Per ogni vertice, si fa una query al modello
    # con una direzione fittizia (es. [0, 0, 1])
    verts_t = torch.tensor(verts, dtype=torch.float32, device=device)
    dirs_t = torch.zeros_like(verts_t)
    dirs_t[...,2] = 1.0  # direzione Z fissa
    with torch.no_grad():
        raw_colors = model(torch.cat([verts_t, dirs_t], dim=-1))
    # raw_colors[..., 0] = densità, raw_colors[..., 1:] = colore (RGB)
    colors = raw_colors[..., 1:].cpu().numpy()  # shape (N, 3)

    # Salvataggio in .ply con colori
    with open("colored_mesh.ply", "w") as f:
        # Header .ply
        f.write("ply\nformat ascii 1.0\n")
        f.write(f"element vertex {len(verts)}\n")
        f.write("property float x\nproperty float y\nproperty float z\n")
        f.write("property uchar red\nproperty uchar green\nproperty uchar blue\n")
        f.write(f"element face {len(faces)}\n")
        f.write("property list uchar int vertex_indices\n")
        f.write("end_header\n")

        # Vertici con colore
        for i, v in enumerate(verts):
            r, g, b = colors[i]
            r, g, b = int(r*255), int(g*255), int(b*255)  # da [0,1] a 0-255
            f.write(f"{v[0]} {v[1]} {v[2]} {r} {g} {b}\n")

        # Facce
        for face in faces:
            f.write(f"3 {face[0]} {face[1]} {face[2]}\n")

    print("Mesh con colore salvata in colored_mesh.ply")

extract_3d_mesh(model, device)
extract_3d_mesh_with_color(model, device)