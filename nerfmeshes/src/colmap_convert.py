import argparse
import sys
import numpy as np
import os
import subprocess
import imageio
import skimage.transform

from shutil import copy2
from data.loaders.load_colmap import read_cameras_binary, read_images_binary, read_points3d_binary

h,w = [0,0]

def load_colmap_data(realdir):
    camerasfile = os.path.join(realdir, 'sparse/0/cameras.bin')
    camdata = read_cameras_binary(camerasfile)

    # cam = camdata[camdata.keys()[0]]
    list_of_keys = list(camdata.keys())
    cam = camdata[list_of_keys[0]]
    print('Cameras', len(cam))

    h, w, f = cam.height, cam.width, cam.params[0]
    # w, h, f = factor * w, factor * h, factor * f
    hwf = np.array([h, w, f]).reshape([3, 1])

    imagesfile = os.path.join(realdir, 'sparse/0/images.bin')
    imdata = read_images_binary(imagesfile)
    image_mapping = {v:i for i, v in enumerate(sorted(imdata.keys()))}

    w2c_mats = []
    bottom = np.array([0, 0, 0, 1.]).reshape([1, 4])

    names = [imdata[k].name for k in imdata]
    print('Images #', len(names))
    perm = np.argsort(names)
    for k in imdata:
        im = imdata[k]
        R = im.qvec2rotmat()
        t = im.tvec.reshape([3, 1])
        m = np.concatenate([np.concatenate([R, t], 1), bottom], 0)
        w2c_mats.append(m)

    w2c_mats = np.stack(w2c_mats, 0)
    c2w_mats = np.linalg.inv(w2c_mats)

    poses = c2w_mats[:, :3, :4].transpose([1, 2, 0])
    poses = np.concatenate(
        [poses, np.tile(hwf[..., np.newaxis], [1, 1, poses.shape[-1]])], 1)

    points3dfile = os.path.join(realdir, 'sparse/0/points3D.bin')
    pts3d = read_points3d_binary(points3dfile)

    # must switch to [-u, r, -t] from [r, -u, t], NOT [r, u, -t]
    poses = np.concatenate(
        [poses[:, 1:2, :], poses[:, 0:1, :], -poses[:, 2:3, :], poses[:, 3:4, :],
         poses[:, 4:5, :]], 1)

    return poses, pts3d, perm, image_mapping


import imageio.v2 as imageio  # safer for compatibility

def save_poses(basedir, poses, pts3d, perm, image_mapping, width=None, height=None):
    pts_arr = []
    vis_arr = []
    for k in pts3d:
        pts_arr.append(pts3d[k].xyz)
        cams = [0] * poses.shape[-1]
        for ind in pts3d[k].image_ids:
            index = image_mapping[ind]
            if len(cams) <= index - 1:
                print('ERROR: the correct camera poses for current point', pts3d[k].id, 'cannot be accessed:', (index))
                return
            else:
                cams[index] = 1
        vis_arr.append(cams)

    pts_arr = np.array(pts_arr)
    vis_arr = np.array(vis_arr)
    print('Points', pts_arr.shape, 'Visibility', vis_arr.shape)

    zvals = np.sum(
        -(pts_arr[:, np.newaxis, :].transpose([2, 0, 1]) - poses[:3, 3:4, :]) * poses[:3, 2:3, :], 0)
    valid_z = zvals[vis_arr == 1]
    print('Depth stats', valid_z.min(), valid_z.max(), valid_z.mean())

    poses_out = []
    bounds_out = []
    for i in perm:
        vis = vis_arr[:, i]
        zs = zvals[:, i]
        zs = zs[vis == 1]
        close_depth, inf_depth = np.percentile(zs, .1), np.percentile(zs, 99.9)

        # Convert 3x5 to 4x4
        pose_3x5 = poses[..., i]  # shape (3, 5)
        pose_3x4 = pose_3x5[:, :4]  # drop intrinsics
        pose_4x4 = np.eye(4)
        pose_4x4[:3, :4] = pose_3x4
        poses_out.append(pose_4x4)

        bounds_out.append([close_depth, inf_depth])

    poses_out = np.stack(poses_out, axis=0)  # (N, 4, 4)
    bounds_out = np.array(bounds_out)        # (N, 2)
    focal = poses[2, 4, 0]                   # Extract focal length from original pose

    # Load and reorder images
    img_dir = os.path.join(basedir, 'images')
    img_files = sorted([
        os.path.join(img_dir, f) for f in os.listdir(img_dir)
        if f.lower().endswith(('jpg', 'jpeg', 'png'))
    ])
    img_files = [img_files[i] for i in perm]  # Reorder to match pose order

    # Load and normalize images
    images = []
    for f in img_files:
        img = imageio.imread(f)[..., :3].astype(np.float32)
        # Assicurati che i valori siano normalizzati tra 0 e 1
        if img.max() > 1.0:
            img = img / 255.0
        images.append(img)
    
    images = np.stack(images, axis=0)  # (N, H, W, 3)
    
    # Print range to verify normalization
    print(f"Image value range: [{images.min()}, {images.max()}]")

    N = poses_out.shape[0]
    poses_3x5 = np.zeros((N, 3, 5), dtype=np.float32)
    for i in range(N):
        Rt = poses_out[i, :3, :4]      # 3×4
        hwf = np.array([h, w, focal])  # h,w,f dalle camere
        poses_3x5[i, :, :4] = Rt
        poses_3x5[i, :, 4]  = hwf
    
    if height is not None or width is not None:
        # prendi dimensioni originali
        H0, W0 = images.shape[1], images.shape[2]
        if height is not None:
            factor = H0 / float(height)
            new_H, new_W = height, int(W0 / factor)
        else:
            factor = W0 / float(width)
            new_W, new_H = width, int(H0 / factor)

        # resize in memoria
        resized = []
        for im in images:
            im_s = skimage.transform.resize(
                im, (new_H, new_W, 3),
                order=1, mode='constant',
                preserve_range=True, anti_aliasing=True
            )
            resized.append(im_s.astype(np.float32))
        images = np.stack(resized, 0)

        # aggiorna metadati in poses_3x5[:, :, 4]
        poses_3x5[:, 0, 4] = new_H
        poses_3x5[:, 1, 4] = new_W
        poses_3x5[:, 2, 4] = focal / factor

    # --- salvataggio .npz con le stesse chiavi del tuo vecchio file .npz ---
    np.savez(
        os.path.join(basedir, 'poses_bounds.npz'),
        poses=poses_3x5,    # (N, 3, 5)
        bds=bounds_out,     # (N, 2)
        focal=focal,
        images=images       # (N, H, W, 3), già normalizzate
    )
    '''
    # Save only in .npz format
        np.savez(os.path.join(basedir, 'poses_bounds.npz'),
                poses=poses_out,
                bds=bounds_out,
                focal=focal,
                images=images)
    '''
             
    print(f"Saved poses data in .npz format")


def minify_v0(basedir, factors=[], resolutions=[]):
    needtoload = False
    for r in factors:
        imgdir = os.path.join(basedir, 'images_{}'.format(r))
        if not os.path.exists(imgdir):
            needtoload = True
    for r in resolutions:
        imgdir = os.path.join(basedir, 'images_{}x{}'.format(r[1], r[0]))
        if not os.path.exists(imgdir):
            needtoload = True
    if not needtoload:
        return

    def downsample(imgs, f):
        sh = list(imgs.shape)
        sh = sh[:-3] + [sh[-3] // f, f, sh[-2] // f, f, sh[-1]]
        imgs = np.reshape(imgs, sh)
        imgs = np.mean(imgs, (-2, -4))
        return imgs

    imgdir = os.path.join(basedir, 'images')
    imgs = [os.path.join(imgdir, f) for f in sorted(os.listdir(imgdir))]
    imgs = [f for f in imgs if
            any([f.endswith(ex) for ex in ['JPG', 'jpg', 'png', 'jpeg', 'PNG']])]
    
    img_data = []
    for img_path in imgs:
        img = imageio.imread(img_path)[..., :3].astype(np.float32)
        if img.max() > 1.0:
            img = img / 255.0
        img_data.append(img)
    
    imgs = np.stack(img_data, 0)
    print(f"Original image value range: [{imgs.min()}, {imgs.max()}]")

    for r in factors + resolutions:
        if isinstance(r, int):
            name = 'images_{}'.format(r)
        else:
            name = 'images_{}x{}'.format(r[1], r[0])
        imgdir = os.path.join(basedir, name)
        if os.path.exists(imgdir):
            continue
        print('Minifying', r, basedir)

        if isinstance(r, int):
            imgs_down = downsample(imgs, r)
        else:
            imgs_down = skimage.transform.resize(imgs, [imgs.shape[0], r[0], r[1],
                                                        imgs.shape[-1]],
                                                 order=1, mode='constant', cval=0,
                                                 clip=True, preserve_range=False,
                                                 anti_aliasing=True,
                                                 anti_aliasing_sigma=None)

        os.makedirs(imgdir)
        for i in range(imgs_down.shape[0]):
            img_to_save = (255 * imgs_down[i]).astype(np.uint8)
            imageio.imwrite(os.path.join(imgdir, 'image{:03d}.png'.format(i)), img_to_save)


def minify(basedir, factors=[], resolutions=[]):
    needtoload = False
    for r in factors:
        imgdir = os.path.join(basedir, 'images_{}'.format(r))
        if not os.path.exists(imgdir):
            needtoload = True
    for r in resolutions:
        imgdir = os.path.join(basedir, 'images_{}x{}'.format(r[1], r[0]))
        if not os.path.exists(imgdir):
            needtoload = True
    if not needtoload:
        return

    from subprocess import check_output

    imgdir = os.path.join(basedir, 'images')
    imgs = [os.path.join(imgdir, f) for f in sorted(os.listdir(imgdir))]
    imgs = [f for f in imgs if
            any([f.endswith(ex) for ex in ['JPG', 'jpg', 'png', 'jpeg', 'PNG']])]
    imgdir_orig = imgdir

    wd = os.getcwd()

    for r in factors + resolutions:
        if isinstance(r, int):
            name = 'images_{}'.format(r)
            resizearg = '{}%'.format(int(100. / r))
        else:
            name = 'images_{}x{}'.format(r[1], r[0])
            resizearg = '{}x{}'.format(r[1], r[0])
        imgdir = os.path.join(basedir, name)
        if os.path.exists(imgdir):
            continue

        print('Minifying', r, basedir)

        os.makedirs(imgdir)
        check_output('cp {}/* {}'.format(imgdir_orig, imgdir), shell=True)

        ext = imgs[0].split('.')[-1]
        args = ' '.join(
            ['mogrify', '-resize', resizearg, '-format', 'png', '*.{}'.format(ext)])
        print(args)
        os.chdir(imgdir)
        check_output(args, shell=True)
        os.chdir(wd)

        if ext != 'png':
            check_output('rm {}/*.{}'.format(imgdir, ext), shell=True)
            print('Removed duplicates')
        print('Done')
        
def load_data(basedir, factor=None, width=None, height=None, load_imgs=True):
    npz_path = os.path.join(basedir, 'poses_bounds.npz')
    if not os.path.exists(npz_path):
        raise FileNotFoundError(f"{npz_path} non trovato")

    # --- 1) Carico self‐contained .npz ---
    data     = np.load(npz_path)
    poses3x5 = data['poses']     # (N, 3, 5)
    bds      = data['bds']       # (N, 2)
    images   = data['images']    # (N, H0, W0, 3)
    focal = float(data['focal'])

    # --- 2) Trasponi poses in (3,5,N) e ricava N,H0,W0 ---
    poses = poses3x5.transpose(1, 2, 0)       # (3,5,N)
    N, H0, W0 = images.shape[0], images.shape[1], images.shape[2]

    # --- 3) Normalizzazione garantita ---
    # se nel .npz c'è già 0–1, ridividi ancora non fa danno:
    imgs = images.astype(np.float32)
    if imgs.max() > 1.0:
        imgs /= 255.0

    # --- 4) Calcolo factor e dimensioni target ---
        # 4) Calcolo factor e dimensioni target
    sfx = ''
    if factor is not None:
        # se passo factor da CLI uso quello
        sfx = f'_{factor}'
    elif height is not None:
        factor = H0 / float(height)
        width  = int(W0 / factor)
        sfx    = f'_{width}x{height}'
    elif width is not None:
        factor = W0 / float(width)
        height = int(H0 / factor)
        sfx    = f'_{width}x{height}'
    else:
        factor = 1.0

    # --- 5) Resize in memoria se serve ---
    if factor != 1.0:
        new_H, new_W = int(H0 / factor), int(W0 / factor)
        resized = []
        for im in imgs:
            im_small = skimage.transform.resize(
                im,
                (new_H, new_W, 3),
                order=1,
                mode='constant',
                preserve_range=True,
                anti_aliasing=True
            )
            resized.append(im_small.astype(np.float32))
        imgs = np.stack(resized, axis=0)

    # --- 6) Aggiorna metadati in poses[:,4,:] ---
    poses[0, 4, :] = imgs.shape[1]   # nuova altezza
    poses[1, 4, :] = imgs.shape[2]   # nuova larghezza
    poses[2, 4, :] = focal / factor  # nuova focale

    if not load_imgs:
        return poses, bds

    print(f"Loaded data: poses {poses.shape}, bds {bds.shape}, imgs {imgs.shape}")
    return poses, bds, imgs, focal



def run_colmap(basedir, match_type):
    logfile_name = os.path.join(basedir, 'colmap_output.txt')
    logfile = open(logfile_name, 'w')

    feature_extractor_args = [
        'colmap', 'feature_extractor',
        '--database_path', os.path.join(basedir, 'database.db'),
        '--image_path', os.path.join(basedir, 'images'),
        '--ImageReader.single_camera', '1',
        # '--SiftExtraction.use_gpu', '0',
    ]
    feat_output = (
        subprocess.check_output(feature_extractor_args, universal_newlines=True))
    logfile.write(feat_output)
    print('Features extracted')

    exhaustive_matcher_args = [
        'colmap', match_type,
        '--database_path', os.path.join(basedir, 'database.db'),
    ]

    match_output = (
        subprocess.check_output(exhaustive_matcher_args, universal_newlines=True))
    logfile.write(match_output)
    print('Features matched')

    p = os.path.join(basedir, 'sparse')
    if not os.path.exists(p):
        os.makedirs(p)

    # mapper_args = [
    #     'colmap', 'mapper',
    #         '--database_path', os.path.join(basedir, 'database.db'),
    #         '--image_path', os.path.join(basedir, 'images'),
    #         '--output_path', os.path.join(basedir, 'sparse'),
    #         '--Mapper.num_threads', '16',
    #         '--Mapper.init_min_tri_angle', '4',
    # ]
    mapper_args = [
        'colmap', 'mapper',
        '--database_path', os.path.join(basedir, 'database.db'),
        '--image_path', os.path.join(basedir, 'images'),
        '--output_path', os.path.join(basedir, 'sparse'),
        # --export_path changed to --output_path in colmap 3.6
        '--Mapper.num_threads', '16',
        '--Mapper.init_min_tri_angle', '4',
        '--Mapper.multiple_models', '0',
        '--Mapper.extract_colors', '0',
    ]

    map_output = (subprocess.check_output(mapper_args, universal_newlines=True))
    logfile.write(map_output)
    logfile.close()
    print('Sparse map created')

    print('Finished running COLMAP, see {} for logs'.format(logfile_name))


def sort_out_images(basedir):
    imfolder = os.path.join(basedir, "images")
    allimfolder = os.path.join(basedir, "all_images")
    if not os.path.exists(allimfolder):
        raise FileNotFoundError(
            "Cannot find folder with all images(Called 'all_images')")
    if not os.path.exists(imfolder):
        os.makedirs(imfolder)
    imagesfile = os.path.join(basedir, 'sparse/0/images.bin')
    imdata = read_images_binary(imagesfile)
    for image in imdata.values():
        copy2(os.path.join(allimfolder, image.name), imfolder)


def gen_poses(basedir, match_type, factors=None, width=None, height=None):
    files_needed = ['{}.bin'.format(f) for f in ['cameras', 'images', 'points3D']]
    if os.path.exists(os.path.join(basedir, 'sparse/0')):
        files_had = os.listdir(os.path.join(basedir, 'sparse/0'))
    else:
        files_had = []
    if not all([f in files_had for f in files_needed]):
        print('Need to run COLMAP')
        try:
            run_colmap(basedir, match_type)
        except:
            raise NotImplementedError("Cannot run colmap! please provide files manually!")
    else:
        print('Don\'t need to run COLMAP')

    print('Post-colmap')

    poses, pts3d, perm, image_mapping = load_colmap_data(basedir)

    save_poses(basedir, poses, pts3d, perm, image_mapping, width, height)

    sort_out_images(basedir)

    if factors is not None:
        print('Factors:', factors)
        minify(basedir, factors)

    print('Done with imgs2poses')

    return True


parser = argparse.ArgumentParser()
parser.add_argument('--match_type', type=str,
					default='exhaustive_matcher', help='type of matcher used.  Valid options: \
					exhaustive_matcher sequential_matcher.  Other matchers not supported at this time')
parser.add_argument('scenedir', type=str,
                    help='input scene directory')
parser.add_argument('--factor', type=int, default=None, 
                    help='downsample factor for images')
parser.add_argument('--width', type=int, default=None,
                    help='target image width (will preserve aspect ratio)')
parser.add_argument('--height', type=int, default=None,
                    help='target image height (will preserve aspect ratio)')
args = parser.parse_args()

if args.match_type != 'exhaustive_matcher' and args.match_type != 'sequential_matcher':
    print('ERROR: matcher type ' + args.match_type + ' is not valid.  Aborting')
    sys.exit()

if __name__=='__main__':
    success = gen_poses(args.scenedir, args.match_type, factors=[args.factor] if args.factor else None, width=args.width, height=args.height)
    
    if success and (args.width is not None or args.height is not None):
        load_data(args.scenedir, factor=args.factor, width=args.width, height=args.height)
        print(f"Images resized to specified dimensions")