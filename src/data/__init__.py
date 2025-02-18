"""
Data processing and loading utilities.
"""
import cv2

def videosampling (file, n_frames):
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



def saveframes(frames):
    """
    Save frames as images.
    """
    for i, frame in enumerate(frames):
        cv2.imwrite(f'frame_{i:04d}.jpg', frame)
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



frames = videosampling('/Users/alessandrosola/projects/pmdscomputervision/src/data/video.mp4', 10)
frames = downscalingimages(frames, 1080, 1080)
frames = greyscale(frames)
saveframes(frames)
