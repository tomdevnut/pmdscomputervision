import open3d as o3d
import numpy as np
import copy

def calculate_metrics(source_cleaned, target, final_transformation, tolerance_for_percentage):
    """
    Calcola metriche di deviazione dettagliate e restituisce la nuvola di punti
    heatmap insieme a un dizionario di metriche.
    """
    source_aligned = copy.deepcopy(source_cleaned).transform(final_transformation)

    # Calcola le distanze punto-punto
    distances = source_aligned.compute_point_cloud_distance(target)
    distances_np = np.asarray(distances)

    # Calcola la percentuale di punti entro la tolleranza specificata
    total_points = len(distances_np)
    if total_points > 0:
        points_within_tolerance = np.sum(distances_np <= tolerance_for_percentage)
        percentage_within_tolerance = (points_within_tolerance / total_points) * 100
    else:
        percentage_within_tolerance = 0

    # Estrapola tutte le metriche richieste
    metrics = {
        'std_deviation': np.std(distances_np),
        'min_deviation': np.min(distances_np),
        'max_deviation': np.max(distances_np),
        'avg_deviation': np.mean(distances_np),
        'accuracy_rmse': np.sqrt(np.mean(np.square(distances_np))),
        'percentage_of_points_within_tolerance': percentage_within_tolerance
    }

    # Crea la nuvola di punti heatmap per la visualizzazione
    heatmap_pcd = copy.deepcopy(source_aligned)
    cmap = o3d.visualization.utility.ColorMapJet()
    
    max_dist_for_color = metrics["max_deviation"]
    if max_dist_for_color == 0: max_dist_for_color = 1.0 # Evita divisione per zero

    heatmap_pcd.colors = cmap.get_color(distances_np / max_dist_for_color)

    return heatmap_pcd, metrics