import sys
from pathlib import Path
from nerfstudio.scripts.train import train_loop
from nerfstudio.scripts.exporter import export_loop
from nerfstudio.configs.method_configs import all_methods

def main_library(project_path_str: str):
    """
        Per ricostruire l'oggetto 3D uso un mix di img e depth map.
        Le depth map sono generate con il Lidar e si sovrappongono alle immagini.
        In questo modo l'img sa dove andare a pescarsi le informazioni 3D
    """
    project_path = Path(project_path_str)

    if not project_path.is_dir():
        print("Non esiste la cartella del progetto specificato")
        sys.exit(1)

    # Uso gaussian-splatting per la ricostruzione 3D, che è un algoritmo simile a NeRF ma più recente
    method = "gaussian-splatting"
    config = all_methods[method].config
    
    config.data = project_path
    config.use_depth = True
    config.viewer.quit_on_train_completion = True
    
    # Avvio il traning con Gaussian Splatting
    train_loop(config)

    # Trova il file di configurazione generato dal training
    try:
        output_dir = project_path / "outputs"
        config_file = next(output_dir.glob("**/config.yml"))
        print(f"Trovato file di configurazione: {config_file}")
    except StopIteration:
        print("Non è stato trovato il file di configurazione dopo il training")
        sys.exit(1)
    # Preparo il percorso di esportazione
    scan_id = 
    export_file = project_path / "exports" / "scan_id.ply" # TODO: sostituire con scan_id
    export_file.parent.mkdir(exist_ok=True)
    
    # Esporto il modello 3D in formato PLY usando Poisson Surface Reconstruction
    export_loop(
        config=config_file,
        method="poisson",
        output_file=export_file
    )

    print("Pipeline Completata")

if __name__ == "__main__":
    project_folder = "/src/data/directory_scan_id"
    main_library(project_folder)