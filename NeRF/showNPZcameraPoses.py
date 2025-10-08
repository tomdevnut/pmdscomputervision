from mpl_toolkits.mplot3d import Axes3D
import numpy as np
import matplotlib.pyplot as plt
import argparse

def get_camera_centers(file):
    data = np.load(file)
    poses = data["poses"]
    camera_centers = poses[:, :3, 3]  # Estrai i centri camera
    return camera_centers

parser = argparse.ArgumentParser()
parser.add_argument("filename_1", type=str)
parser.add_argument("filename_2", type=str)
args = parser.parse_args()

centers_1 = get_camera_centers(args.filename_1)
centers_2 = get_camera_centers(args.filename_2)

fig = plt.figure(figsize=(12, 6))

ax1 = fig.add_subplot(1, 2, 1, projection='3d')
ax1.scatter(centers_1[:, 0], centers_1[:, 1], centers_1[:, 2])
ax1.set_title("Camera Poses - File 1")

ax2 = fig.add_subplot(1, 2, 2, projection='3d')
ax2.scatter(centers_2[:, 0], centers_2[:, 1], centers_2[:, 2])
ax2.set_title("Camera Poses - File 2")

plt.tight_layout()
plt.show()
