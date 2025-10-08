import numpy as np
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("filename", type=str)

args = parser.parse_args()
    
file = args.filename

data = np.load(file)

images, poses, focal = data["images"], data["poses"], data["focal"]

print(images.shape) # (106, 100, 100, 3)
print(poses.shape) # (106, 4, 4)
print(focal) # array(138.8888789)

fig, ax = plt.subplots(1, 5, figsize=(20, 12))
for i in range(5):
    ax[i].imshow(images[i])
plt.show()