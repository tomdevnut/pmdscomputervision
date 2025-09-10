import open3d as o3d
import copy

def preprocess_point_cloud(pcd, voxel_size):
    """
        Faccio downscaling per velocizzare il processo di FPFH (descrizione della geometria locale di ogni punto)
    """
    # Downscaling della nuvola di punti
    pcd_down = pcd.voxel_down_sample(voxel_size)

    # Stima delle normali, perchè la uso per stimare gli angoli con cui FPFH andrà ad associare tra di loro punti simili
    radius_normal = voxel_size * 2
    pcd_down.estimate_normals(
        o3d.geometry.KDTreeSearchParamHybrid(radius=radius_normal, max_nn=30))

    # Uso FPFH per l'allineamento grezzo
    radius_feature = voxel_size * 5
    pcd_fpfh = o3d.pipelines.registration.compute_fpfh_feature(
        pcd_down,
        o3d.geometry.KDTreeSearchParamHybrid(radius=radius_feature, max_nn=100))
    return pcd_down, pcd_fpfh

def align_models(source_path, target_path, output_path):
    """
        Allineo sia in maniera grezza (RANSAC su FPFH) che precisa (ICP Point-to-Plane)
    """
    # Carica i modelli
    source_pcd = o3d.io.read_point_cloud(source_path)
    target_pcd = o3d.io.read_point_cloud(target_path)
    
    # Crea una copia della sorgente che verrà trasformata, così poi posso riutilizzarla per ICP
    source_transformed = copy.deepcopy(source_pcd)

    # Gioco un po con questo parametro, è la dimensione del voxel per il downsampling
    voxel_size = 0.05  # 5cm

    # Faccio partire l'allineamento grezzo con FPFH + RANSAC
    source_down, source_fpfh = preprocess_point_cloud(source_pcd, voxel_size)
    target_down, target_fpfh = preprocess_point_cloud(target_pcd, voxel_size)

    result_ransac = o3d.pipelines.registration.registration_ransac_based_on_feature_matching(
        source_down, target_down,
        source_fpfh, target_fpfh,
        True, # Mutual filter
        voxel_size * 1.5,
        o3d.pipelines.registration.TransformationEstimationPointToPoint(False),
        3, [
            o3d.pipelines.registration.CorrespondenceCheckerBasedOnEdgeLength(0.9),
            o3d.pipelines.registration.CorrespondenceCheckerBasedOnDistance(voxel_size * 1.5)
        ], o3d.pipelines.registration.RANSACConvergenceCriteria(100000, 0.999))
    
    # Applica la trasformazione grezza per la stima iniziale dell'ICP
    source_transformed.transform(result_ransac.transformation)

    # Parto con la stima precisa usando ICP Point-to-Plane
    initial_transformation = result_ransac.transformation

    result_icp = o3d.pipelines.registration.registration_icp(
        source_pcd,
        target_pcd,
        0.02,  # TODO: giocare un po con questo parametro, è il raggio massimo per considerare due punti corrispondenti (2cm)
        initial_transformation,
        o3d.pipelines.registration.TransformationEstimationPointToPlane())

    # Applica la trasformazione finale e precisa alla nuvola di punti sorgente
    source_pcd.transform(result_icp.transformation)

    # Salvo il risultato
    o3d.io.write_point_cloud(output_path, source_pcd)
    print("Allineamento completato")

if __name__ == "__main__":
    # TODO: sistemo i vari PATH
    source_file = "/src/data/directory_scan_id/scene_extracted.ply"
    target_file = "/src/data/directory_scan_id/step.ply"
    output_file = "/src/data/directory_scan_id/scene_aligned.ply"

    align_models(source_file, target_file, output_file)