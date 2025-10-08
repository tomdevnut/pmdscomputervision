import os
import tempfile
import requests
from firebase_admin import firestore, storage
import cadquery as cq
import numpy as np
import open3d as o3d
import pipeline.config as config
import pipeline.preprocess as preprocess
import pipeline.registration as registration
import pipeline.analysis as analysis

def pipeline_worker(scan_url, step_url, scan_id):
    """
    Funzione che esegue la pipeline di elaborazione in un thread separato.
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
        print(f"Directory temporanea creata: {temp_dir}")
        
        # Download scan file
        scan_filename = os.path.join(temp_dir, "scan.ply")
        print(f"Downloading scan from {scan_url}")
        _download_file(scan_url, scan_filename)
        print(f"Scan downloaded to {scan_filename}")
        
        # Download step file
        step_filename = os.path.join(temp_dir, "step.step")
        print(f"Downloading step from {step_url}")
        _download_file(step_url, step_filename)
        
        scan_ref.update({'progress': 10})
        
        # Convert step to ply
        step_ply_filename = os.path.join(temp_dir, "step.ply")
        _convert_step_to_ply(step_filename, step_ply_filename, tolerance=config.TOLERANCE)
        
        scan_ref.update({'progress': 20})
        
        # --------------------------------------------------------------------
        # --- INIZIO LOGICA PRINCIPALE (MAIN) DI ELABORAZIONE ---
        # --------------------------------------------------------------------

        print("Caricamento nuvole di punti con Open3D...")
        target_pcd = o3d.io.read_point_cloud(step_ply_filename)
        source_pcd = o3d.io.read_point_cloud(scan_filename)
        
        # 1. Preprocessing
        source_cleaned = preprocess.segment_and_clean(
            source_pcd,
            config.PLANE_DISTANCE_THRESHOLD,
            config.OUTLIER_NB_NEIGHBORS,
            config.OUTLIER_STD_RATIO
        )
        scan_ref.update({'progress': 40})

        # 2. Registrazione Globale
        initial_transform = registration.run_global_registration(
            source_cleaned, 
            target_pcd, 
            config.VOXEL_SIZE_FEATURES
        )
        scan_ref.update({'progress': 60})
        
        # 3. Registrazione Locale (ICP)
        final_transform = registration.refine_with_icp(
            source_cleaned,
            target_pcd,
            initial_transform,
            config.ICP_THRESHOLD
        )
        scan_ref.update({'progress': 80})

        # 4. Analisi e calcolo delle metriche
        heatmap_pcd, metrics = analysis.calculate_metrics(
            source_cleaned,
            target_pcd,
            final_transform,
            config.ANALYSIS_TOLERANCE_METERS # Passa la tolleranza dal file config
        )
        print(f"Metriche calcolate: {metrics}")
        
        # 5. Salvataggio del risultato e preparazione per l'upload
        print("Salvataggio del file heatmap...")
        heatmap_ply_path = os.path.join(temp_dir, "heatmap_scan.ply")
        o3d.io.write_point_cloud(heatmap_ply_path, heatmap_pcd)
        
        scan_ref.update({'progress': 90})

        # Upload del file heatmap su Firebase Storage
        bucket = storage.bucket()
        heatmap_blob = bucket.blob(f"comparisons/{scan_id}.ply")
        heatmap_blob.upload_from_filename(heatmap_ply_path)

        # Aggiornamento del documento 'stats' su Firestore con le nuove metriche
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
        # --- FINE LOGICA PRINCIPALE ---
        # --------------------------------------------------------------------
        
        print(f"Pipeline completata per scan_id: {scan_id}")

        scan_ref.update({'status': 2, 'progress': 100})
        
    except Exception as e:
        print(f"Errore nella pipeline per scan_id {scan_id}: {e}")
        try:
            db = firestore.client()
            scan_ref = db.collection('scans').document(scan_id)
            scan_ref.update({'status': -1})
        except Exception as db_error:
            print(f"Impossibile aggiornare Firestore con lo stato di errore: {db_error}")
        
        # Re-raise the exception so queue_manager can handle retry
        raise
        
    finally:
        # Elimino i file temporanei
        print(f"Pulizia file temporanei per scan_id: {scan_id}")
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
        
        print(f"STEP convertito in PLY con {len(vertices)} vertici e {len(faces)} facce")
        
    except Exception as e:
        raise Exception(f"Errore conversione STEP->PLY: {e}")