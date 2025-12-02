import open3d as o3d
import numpy as np
import matplotlib.cm as cm

def analyze_and_compare(aligned_scan_path, original_path, heatmap_output_path, tolerance_mm=2.0):
    """
        Calcolo le distanze tra la scansione che ho allineato ed il file originale di progetto
        Poi genero le varie statistiche e la heatmap 3D
        Le statisiche che genero sono le seguenti:
            - Errore Quadratico Medio
            - Deviazione Media Assoluta
            - Deviazione Standard
            - Deviazione Massima
            - Deviazione Minima
            - Percentuale di punti entro la tolleranza (accuracy)
    """    
    aligned_scan_pcd = o3d.io.read_point_cloud(aligned_scan_path)
    original_mesh = o3d.io.read_triangle_mesh(original_path)

    # Calcolo le normali per la mesh originale, necessarie per il calcolo delle distanze
    original_mesh.compute_vertex_normals()

    # Calcolo le distanze punto a punto
    distances = aligned_scan_pcd.compute_point_cloud_distance(original_mesh)
    distances_mm = np.asarray(distances) * 1000  # Le converto in mm
    # TODO: vedere se ha senso convertirle in mm

    # Calcolo le statistiche
    mean_abs_dev = np.mean(np.abs(distances_mm))
    rms_error = np.sqrt(np.mean(distances_mm**2))
    std_dev = np.std(distances_mm)
    max_dev = np.max(distances_mm)
    min_dev = np.min(distances_mm)
    
    # Calcolo percentuale entro tolleranza
    points_in_tolerance = np.sum(np.abs(distances_mm) <= tolerance_mm)
    percentage_in_tolerance = (points_in_tolerance / len(distances_mm)) * 100

    print(f"Errore Quadratico Medio: {rms_error:.4f} mm")
    print(f"Deviazione Media Assoluta (MAD): {mean_abs_dev:.4f} mm")
    print(f"Deviazione Standard: {std_dev:.4f} mm")
    print(f"Deviazione Massima (eccesso): {max_dev:.4f} mm")
    print(f"Deviazione Minima (mancanza): {min_dev:.4f} mm")
    print(f"Accuracy: {percentage_in_tolerance:.2f}%")

    # TODO: le statistiche andranno caricate su firestore

    # Genero la heatmap 3D (file comparison.ply)    
    vis_range = 5.0
    norm_distances = (np.clip(distances_mm, -vis_range, vis_range) + vis_range) / (2 * vis_range)
    colors = cm.jet(norm_distances)[:, :3] # Mappa di colori blu-verde-giallo-rosso

    # Crea una nuova nuvola di punti con i colori della heatmap
    heatmap_pcd = o3d.geometry.PointCloud()
    heatmap_pcd.points = aligned_scan_pcd.points
    heatmap_pcd.colors = o3d.utility.Vector3dVector(colors)

    o3d.io.write_point_cloud(heatmap_output_path, heatmap_pcd)
    print("Pipeline di analisi completata")

if __name__ == "__main__":
    # TODO: sistemo i vari PATH
    aligned_scan_file = "/src/data/directory_scan_id/scene_aligned.ply"
    cad_file = "/src/data/directory_scan_id/step.ply"
    output_file = "/src/data/directory_scan_id/comparison.ply"

    analyze_and_compare(aligned_scan_file, cad_file, output_file)