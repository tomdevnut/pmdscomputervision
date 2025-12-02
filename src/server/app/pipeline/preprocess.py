import open3d as o3d

def segment_and_clean(pcd, plane_dist, outlier_neighbors, outlier_std):
    """
    Removes the main plane using RANSAC and cleans the point cloud using statistical outlier removal.
    """
    plane_model, inliers = pcd.segment_plane(
        distance_threshold=plane_dist,
        ransac_n=3,
        num_iterations=1000
    )
    # Extract everything that is NOT the plane
    pcd_segmented = pcd.select_by_index(inliers, invert=True)


    pcd_cleaned, _ = pcd_segmented.remove_statistical_outlier(
        nb_neighbors=outlier_neighbors,
        std_ratio=outlier_std
    )
    
    return pcd_cleaned