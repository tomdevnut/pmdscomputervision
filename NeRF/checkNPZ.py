import numpy as np
import matplotlib.pyplot as plt
import argparse

def check_npz(file):
    data = np.load(file)

    images = data["images"]
    poses = data["poses"]
    focal = data["focal"]

    print(f"Images shape: {images.shape}")   # (N, H, W, 3)
    print(f"Poses shape: {poses.shape}")     # (N, 4, 4)
    print(f"Focale: {focal}")

    # Controllo la normalizzazione dei pixel delle immagini
    min_val, max_val = images.min(), images.max()
    print(f"Pixel range: {min_val:.3f} to {max_val:.3f}")
    if not (0.0 <= min_val and max_val <= 1.0):
        print("Le immagini non sono normalizzate (valori fuori da [0,1])")

    # Distribuzione delle camera poses
    centers = poses[:, :3, 3]
    mean_center = np.mean(centers, axis=0)
    max_extent = np.max(np.linalg.norm(centers - mean_center, axis=1))

    print(f"Centro medio camere: {mean_center}")
    print(f"Estensione massima dalle pose: {max_extent:.3f}")
    if max_extent > 10:
        print("Le poses sono molto disperse. Potrebbe servire scalare la scena.")

    # Plot delle camera poses
    fig = plt.figure(figsize=(10, 4))
    ax = fig.add_subplot(121, projection='3d')
    ax.scatter(centers[:, 0], centers[:, 1], centers[:, 2])
    ax.set_title("Camera Poses")

    # Plot delle immagini
    ax2 = fig.add_subplot(122)
    idx = 0
    ax2.imshow(images[idx])
    ax2.set_title(f"Image sample (idx {idx})")

    plt.tight_layout()
    plt.show()

parser = argparse.ArgumentParser()
parser.add_argument("filename", type=str)
args = parser.parse_args()
file = args.filename

check_npz(file)
