import os
import tempfile
import requests
from firebase_admin import firestore, storage
import cadquery as cq
import numpy as np
import open3d as o3d
from app.pipeline import config
from app.pipeline import preprocess
from app.pipeline import registration
from app.pipeline import analysis
from flask import current_app as app

def pipeline_worker(scan_url, step_url, scan_id):
    """
    Main pipeline worker function.
    Downloads files, processes them, uploads results, and updates Firestore.
    """
    scan_filename = None
    step_filename = None
    temp_dir = None
    
    try:
        db = firestore.client()
        scan_ref = db.collection('scans').document(scan_id)
        scan_ref.update({'status': 1, 'progress': 0})

        # Create a temporary directory for this scan
        temp_dir = tempfile.mkdtemp(prefix=f"scan_{scan_id}_")
        app.logger.info(f"Temporary directory created: {temp_dir}")
        
        # Download scan file
        scan_filename = os.path.join(temp_dir, "scan.ply")
        app.logger.info(f"Downloading scan from {scan_url}")
        _download_file(scan_url, scan_filename)
        app.logger.info(f"Scan downloaded to {scan_filename}")

        # Download step file
        step_filename = os.path.join(temp_dir, "step.step")
        app.logger.info(f"Downloading step from {step_url}")
        _download_file(step_url, step_filename)
        
        scan_ref.update({'progress': 10})
        
        # Convert step to ply
        step_ply_filename = os.path.join(temp_dir, "step.ply")
        _convert_step_to_ply(step_filename, step_ply_filename, tolerance=config.TOLERANCE)
        
        scan_ref.update({'progress': 20})
        
        # --------------------------------------------------------------------
        # --- BEGINNING OF MAIN PROCESSING LOGIC ---
        # --------------------------------------------------------------------

        app.logger.info("Loading point clouds with Open3D...")
        target_pcd = o3d.io.read_point_cloud(step_ply_filename)
        source_pcd = o3d.io.read_point_cloud(scan_filename)
        
        # 1. Preprocessing
        app.logger.info("Starting preprocessing...")
        source_cleaned = preprocess.segment_and_clean(
            source_pcd,
            config.PLANE_DISTANCE_THRESHOLD,
            config.OUTLIER_NB_NEIGHBORS,
            config.OUTLIER_STD_RATIO
        )
        scan_ref.update({'progress': 40})

        # 2. Global Registration
        app.logger.info("Starting global registration...")
        initial_transform = registration.run_global_registration(
            source_cleaned, 
            target_pcd, 
            config.VOXEL_SIZE_FEATURES
        )
        scan_ref.update({'progress': 60})

        # 3. Local Registration (ICP)
        app.logger.info("Refining with ICP...")
        final_transform = registration.refine_with_icp(
            source_cleaned,
            target_pcd,
            initial_transform,
            config.ICP_THRESHOLD
        )
        scan_ref.update({'progress': 80})

        # 4. Analysis and metrics calculation
        app.logger.info("Calculating metrics...")
        heatmap_pcd, metrics = analysis.calculate_metrics(
            source_cleaned,
            target_pcd,
            final_transform,
            config.ANALYSIS_TOLERANCE_METERS # Pass the tolerance from the config file
        )
        app.logger.info(f"Calculated metrics: {metrics}")

        # 5. Save the result and prepare for upload
        app.logger.info("Saving heatmap file...")
        heatmap_ply_path = os.path.join(temp_dir, "heatmap_scan.ply")
        o3d.io.write_point_cloud(heatmap_ply_path, heatmap_pcd)
        
        scan_ref.update({'progress': 90})

        # Upload heatmap file to Firebase Storage
        bucket = storage.bucket()
        heatmap_blob = bucket.blob(f"comparisons/{scan_id}.ply")
        heatmap_blob.upload_from_filename(heatmap_ply_path)

        # Update the 'stats' document in Firestore with the new metrics
        stats_doc_ref = db.collection('stats').document(scan_id)
        stats_doc_ref.set({
            'std_deviation': metrics['std_deviation'],
            'min_deviation': metrics['min_deviation'],
            'max_deviation': metrics['max_deviation'],
            'avg_deviation': metrics['avg_deviation'],
            'accuracy': metrics['accuracy_rmse'],
            'ppwt': metrics['percentage_of_points_within_tolerance'],
        })
        
        # --------------------------------------------------------------------
        # --- END OF MAIN PROCESSING LOGIC ---
        # --------------------------------------------------------------------

        app.logger.info(f"Pipeline completed for scan_id: {scan_id}")

        scan_ref.update({'status': 2, 'progress': 100})
        
    except Exception as e:
        app.logger.error(f"Error in pipeline for scan_id {scan_id}: {e}")
        try:
            db = firestore.client()
            scan_ref = db.collection('scans').document(scan_id)
            scan_ref.update({'status': -1})
        except Exception as db_error:
            app.logger.error(f"Failed to update Firestore with error status: {db_error}")
        
        # Re-raise the exception so queue_manager can handle retry
        raise
        
    finally:
        # Clean up temporary files
        app.logger.info(f"Cleaning up temporary files for scan_id: {scan_id}")
        if temp_dir and os.path.exists(temp_dir):
            import shutil
            shutil.rmtree(temp_dir)


def _download_file(url, destination_path):
    """
    Download a file from a URL (Firebase Storage signed URL)
    """
    response = requests.get(url, stream=True)
    response.raise_for_status()
    
    with open(destination_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)


def _convert_step_to_ply(step_path, ply_output_path, tolerance=0.01):
    """
    Convert a STEP file to PLY format using CadQuery
    
    Args:
        step_path: Path to input STEP file
        ply_output_path: Path to output PLY file
        tolerance: Meshing tolerance (smaller = more detailed, default 0.01mm)
    """
    try:
        # Import the STEP file
        result = cq.importers.importStep(step_path)
        
        # Generate mesh with specified tolerance
        # The tolerance controls mesh density
        mesh_data = result.val().tessellate(tolerance)
        vertices, faces = mesh_data[0], mesh_data[1]
        
        # Write PLY file
        with open(ply_output_path, 'w') as f:
            # Write header
            f.write("ply\n")
            f.write("format ascii 1.0\n")
            f.write(f"element vertex {len(vertices)}\n")
            f.write("property float x\n")
            f.write("property float y\n")
            f.write("property float z\n")
            f.write(f"element face {len(faces)}\n")
            f.write("property list uchar int vertex_indices\n")
            f.write("end_header\n")
            
            # Write vertices
            for vertex in vertices:
                f.write(f"{vertex[0]} {vertex[1]} {vertex[2]}\n")
            
            # Write faces
            for face in faces:
                f.write(f"3 {face[0]} {face[1]} {face[2]}\n")

        app.logger.info(f"STEP successfully converted to PLY with {len(vertices)} vertices and {len(faces)} faces")

    except Exception as e:
        raise Exception(f"Error converting STEP to PLY: {e}")