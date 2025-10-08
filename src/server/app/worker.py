import os
import tempfile
import requests
from firebase_admin import firestore, storage
import cadquery as cq
import numpy as np

def pipeline_worker(scan_url, step_url, scan_id):
    """
    Funzione che esegue la pipeline di elaborazione in un thread separato.
    """
    scan_filename = None
    step_filename = None
    temp_dir = None
    
    try:
        # Create a temporary directory for this scan
        temp_dir = tempfile.mkdtemp(prefix=f"scan_{scan_id}_")
        print(f"Created temporary directory: {temp_dir}")
        
        # Download scan file
        scan_filename = os.path.join(temp_dir, "scan.ply")
        print(f"Downloading scan from {scan_url}")
        _download_file(scan_url, scan_filename)
        print(f"Scan downloaded to {scan_filename}")
        
        # Download step file
        step_filename = os.path.join(temp_dir, "step.step")
        print(f"Downloading step from {step_url}")
        _download_file(step_url, step_filename)
        print(f"Step downloaded to {step_filename}")
        
        # Update status to processing
        db = firestore.client()
        scan_ref = db.collection('scans').document(scan_id)
        scan_ref.update({
            'status': 1,  # Processing
            'progress': 10
        })
        
        # Convert step to ply
        step_ply_filename = os.path.join(temp_dir, "step.ply")
        print(f"Converting STEP to PLY...")
        _convert_step_to_ply(step_filename, step_ply_filename)
        print(f"STEP converted to PLY: {step_ply_filename}")
        
        scan_ref.update({'progress': 30})
        
        # Call functions in pipeline module to process the scan
        # TODO: Implement pipeline processing
        # from pipeline.alignment import align_scan
        # from pipeline.analysis import analyze_and_compare
        
        # aligned_scan_path = os.path.join(temp_dir, "scene_aligned.ply")
        # align_scan(scan_filename, step_ply_filename, aligned_scan_path)
        
        # scan_ref.update({'progress': 60})
        
        # heatmap_output_path = os.path.join(temp_dir, "comparison.ply")
        # analyze_and_compare(aligned_scan_path, step_ply_filename, heatmap_output_path)
        
        # scan_ref.update({'progress': 90})
        
        print(f"Pipeline completata per scan_id: {scan_id}")

        # Aggiorno lo stato della scansione su Firestore
        scan_ref.update({
            'status': 2,  # Elaborazione completata
            'progress': 100
        })

        # TODO: Caricare i risultati su Firebase Storage e Firestore
        stats_doc_ref = db.collection('stats').document(scan_id)
        stats_doc_ref.set({
            'accuracy': 0.95,  # Esempio di dato, sostituire con i dati reali
        })
        
    except Exception as e:
        print(f"Errore nella pipeline per scan_id {scan_id}: {e}")
        try:
            db = firestore.client()
            scan_ref = db.collection('scans').document(scan_id)
            scan_ref.update({
                'status': -1  # Errore durante l'elaborazione
            })
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
        
        # Extract vertices and faces
        vertices = mesh_data[0]  # List of (x, y, z) tuples
        faces = mesh_data[1]     # List of (v1, v2, v3) tuples
        
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
        
        print(f"Successfully converted STEP to PLY with {len(vertices)} vertices and {len(faces)} faces")
        
    except Exception as e:
        raise Exception(f"Failed to convert STEP to PLY: {e}")