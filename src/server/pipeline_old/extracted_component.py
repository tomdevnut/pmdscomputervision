import open3d as o3d
import numpy as np

def extracted_component(input_file: str, output_file: str):
    """
        Carico il file ply della scena e cerco di isolare l'oggetto principale.
        Prima uso RANSAC per rimuovere il pavimento/muri, poi DBSCAN per isolare il cluster più grande.
    """

    scene_pcd = o3d.io.read_point_cloud(input_file)
    if not scene_pcd.has_points():
        print("La nuvola di punti di input è vuota")
        return

    # Uso RANSAC e rimuovo il pavimento o i muri
    # TODO: giocare un po con questi parametri
    plane_model, inliers = scene_pcd.segment_plane(distance_threshold=0.01,
                                                   ransac_n=3,
                                                   num_iterations=1000)
    pcd_senza_pavimento = scene_pcd.select_by_index(inliers, invert=True)
    print(f"Rimossi {len(inliers)} punti, ne rimangono: {len(pcd_senza_pavimento.points)}")

    # Ora isolo il cluster con DBSCAN
    # TODO: giocare un po con questi parametri
    labels = np.array(pcd_senza_pavimento.cluster_dbscan(eps=0.02, min_points=10, print_progress=False))

    unique_labels, counts = np.unique(labels[labels != -1], return_counts=True)
    if len(unique_labels) == 0:
        print("Nessun cluster trovato")
        return

    # Trovo il cluster più grande, quello sarà il nostro oggetto
    largest_cluster_label = unique_labels[counts.argmax()]

    indices_oggetto = np.where(labels == largest_cluster_label)[0]
    oggetto_pcd = pcd_senza_pavimento.select_by_index(indices_oggetto)

    # Salvo il risultato
    o3d.io.write_point_cloud(output_file, oggetto_pcd)
    print("Oggetto isolato")


if __name__ == "__main__":
    # TODO: aggiungere input ed output del progetto
    input_path = "/src/data/directory_scan_id/scene.ply"
    output_path = "/src/data/directory_scan_id/scene_extracted.ply"
    extracted_component(input_path, output_path)