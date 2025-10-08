"""
Data processing and loading utilities.
"""
import cv2
import argparse
import os

def videosampling(file, n_frames):
    """
    Sample n_frames from a video file.
    """
    # Open video file
    cap = cv2.VideoCapture(file)
    # Get total number of frames
    n_frames_total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    # Sample frames
    frames = []
    for i in range(n_frames):
        # Calculate frame index
        frame_idx = int(i * n_frames_total / n_frames)
        # Set frame index
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
        # Read frame
        ret, frame = cap.read()
        if ret:
            frames.append(frame)
    # Close video file
    cap.release()
    return frames


def saveframes(frames, output_dir="."):
    """
    Save frames as images.
    
    Args:
        frames: List of frames to save
        output_dir: Directory to save frames (default: current directory)
    """
    os.makedirs(output_dir, exist_ok=True)
    for i, frame in enumerate(frames):
        cv2.imwrite(os.path.join(output_dir, f'frame_{i:04d}.jpg'), frame)
    return True


def downscalingimages(frames, max_width, max_height):
    """
    Downscale images without altering the aspect ratio.
    """
    def downscale_frame(frame, max_width, max_height):
        height, width = frame.shape[:2]
        aspect_ratio = width / height

        if width > max_width or height > max_height:
            if width / max_width > height / max_height:
                new_width = max_width
                new_height = int(max_width / aspect_ratio)
            else:
                new_height = max_height
                new_width = int(max_height * aspect_ratio)

            frame = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)

        return frame

    return [downscale_frame(frame, max_width, max_height) for frame in frames]

def greyscale(frames):
    """
    Convert images to greyscale.
    """
    return [cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) for frame in frames]


def process_video(video_path, n_frames=10, apply_downscale=False, max_width=1080, max_height=1080, 
                 apply_greyscale=False, output_dir="."):
    """
    Process a video with customizable operations.
    
    Args:
        video_path: Path to the video file
        n_frames: Number of frames to sample
        apply_downscale: Whether to downscale the frames
        max_width: Maximum width for downscaled frames
        max_height: Maximum height for downscaled frames
        apply_greyscale: Whether to convert frames to greyscale
        output_dir: Directory to save frames
    
    Returns:
        List of processed frames
    """
    # Sample frames
    frames = videosampling(video_path, n_frames)
    
    # Apply downscaling if requested
    if apply_downscale:
        frames = downscalingimages(frames, max_width, max_height)
    
    # Apply greyscale if requested
    if apply_greyscale:
        frames = greyscale(frames)
    
    # Save frames
    saveframes(frames, output_dir)
    
    return frames


def main():
    """Parse command line arguments and process video."""
    parser = argparse.ArgumentParser(description='Sample and process frames from a video file.')
    parser.add_argument('video_path', help='Path to the video file')
    parser.add_argument('--frames', type=int, default=100, help='Number of frames to sample (default: 10)')
    parser.add_argument('--downscale', action='store_true', help='Downscale images')
    parser.add_argument('--width', type=int, default=1080, help='Maximum width for downscaled images (default: 1080)')
    parser.add_argument('--height', type=int, default=1080, help='Maximum height for downscaled images (default: 1080)')
    parser.add_argument('--greyscale', action='store_true', help='Convert images to greyscale')
    parser.add_argument('--output', default=".", help='Directory to save frames (default: current directory)')
    
    args = parser.parse_args()
    
    process_video(
        video_path=args.video_path,
        n_frames=args.frames,
        apply_downscale=args.downscale,
        max_width=args.width,
        max_height=args.height,
        apply_greyscale=args.greyscale,
        output_dir=args.output
    )


if __name__ == "__main__":
    main()
