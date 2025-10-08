# --- Preprocessing Parameters ---
# RANSAC plane segmentation: Max distance from a point to be considered in the plane.
PLANE_DISTANCE_THRESHOLD = 0.02
# Statistical outlier removal
OUTLIER_NB_NEIGHBORS = 20
OUTLIER_STD_RATIO = 2.0

# --- Registration Parameters ---
# Voxel size for feature computation (key parameter for global registration)
VOXEL_SIZE_FEATURES = 0.05
# ICP refinement distance threshold
ICP_THRESHOLD = 0.02

# --- Analysis Parameters ---
# Tolerance for percentage of points within this distance to be considered "good"
ANALYSIS_TOLERANCE_METERS = 0.01 # Units in meters