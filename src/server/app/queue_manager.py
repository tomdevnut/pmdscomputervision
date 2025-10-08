import threading
from queue import Queue
from app.worker import pipeline_worker
from firebase_admin import firestore

class ScanQueueManager:
    def __init__(self):
        self.scan_queue = Queue()
        self.processing = False
        self.lock = threading.Lock()
        self.current_scan = None
        
    def add_scan(self, scan_data):
        """Add a scan to the queue"""
        self.scan_queue.put(scan_data)
        print(f"Added scan {scan_data.get('scan_id')} to queue. Queue size: {self.scan_queue.qsize()}")
        self._process_next()
    
    def _process_next(self):
        """Process the next scan in the queue if not already processing"""
        with self.lock:
            if self.processing or self.scan_queue.empty():
                return
            
            self.processing = True
            self.current_scan = self.scan_queue.get()
        
        print(f"Starting processing of scan {self.current_scan.get('scan_id')}")
        
        # Start worker in a new thread
        worker_thread = threading.Thread(
            target=self._worker_wrapper,
            args=(self.current_scan['scan_id'], self.current_scan['scan_url'], self.current_scan['step_url'])
        )
        worker_thread.start()
    
    def _worker_wrapper(self, scan_id, scan_url, step_url):
        """Wrapper around pipeline_worker to handle completion and failures"""
        try:
            pipeline_worker(scan_url, step_url, scan_id)
            print(f"Successfully completed scan {scan_id}")
            self._on_scan_complete(success=True)
        except Exception as e:
            print(f"Failed to process scan {scan_id}: {e}")
            self._on_scan_complete(success=False)
    
    def _on_scan_complete(self, success):
        """Called when a scan finishes processing"""
        #with self.lock:
            #if not success and self.current_scan:
                # Re-add failed scan to the end of the queue
                #print(f"Re-queueing failed scan {self.current_scan.get('scan_id')}")
                #self.scan_queue.put(self.current_scan)
            
            #self.current_scan = None
            #self.processing = False
        
        # Process next scan
        self._process_next()
    
    def get_queue_size(self):
        """Get the current queue size"""
        return self.scan_queue.qsize()

# Global queue manager instance
queue_manager = ScanQueueManager()