import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:io';
import 'dart:math' as math;

class LidarScannerScreen extends StatefulWidget {
  @override
  _LidarScannerScreenState createState() => _LidarScannerScreenState();
}

class _LidarScannerScreenState extends State<LidarScannerScreen> {
  late ARKitController arkitController;
  bool isScanning = false;
  bool isProcessing = false;
  String? scanStatus;
  List<vector.Vector3> scannedPoints = [];
  List<ARKitNode> visualNodes = [];

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner LiDAR 3D'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Stack(
        children: [
          // Vista AR con LiDAR
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            configuration: ARKitConfiguration.worldTracking,
            showFeaturePoints: true,
            planeDetection: ARPlaneDetection.vertical,
            detectionImages: const <ARKitReferenceImage>[],
            enableTapRecognizer: true,
            enablePanRecognizer: true,
            enablePinchRecognizer: true,
            enableRotationRecognizer: true,
          ),

          // Overlay UI
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    scanStatus ?? 'Pronto per la scansione',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isProcessing) SizedBox(height: 10),
                  if (isProcessing)
                    LinearProgressIndicator(
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                ],
              ),
            ),
          ),

          // Controlli in basso
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Pulsante principale di scansione
                Center(
                  child: GestureDetector(
                    onTap: isProcessing ? null : toggleScanning,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isScanning ? Colors.red : Colors.blue,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isScanning ? Icons.stop : Icons.camera,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Pulsanti secondari
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Pulsante reset
                    ElevatedButton.icon(
                      onPressed: isProcessing ? null : resetScan,
                      icon: Icon(Icons.refresh),
                      label: Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Pulsante salva e carica
                    ElevatedButton.icon(
                      onPressed: (scannedPoints.isNotEmpty && !isProcessing)
                          ? saveAndUploadScan
                          : null,
                      icon: Icon(Icons.cloud_upload),
                      label: Text('Salva e Carica'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController controller) {
    this.arkitController = controller;

    // Gestione tap per aggiungere punti durante la scansione
    arkitController.onNodeTap = (nodes) {
      if (isScanning && nodes.isNotEmpty) {
        final tappedNodeName = nodes.first; // è una String
        final tappedNode = visualNodes.firstWhere(
          (node) => node.name == tappedNodeName,
        );

        if (tappedNode != null && tappedNode.position != null) {
          addScannedPoint(tappedNode.position!);
        }
      }
    };

    // Gestione piani rilevati (per LiDAR)
    arkitController.onAddNodeForAnchor = (anchor) {
      if (isScanning && anchor is ARKitPlaneAnchor) {
        processPlaneSurface(anchor);
      }
    };

    arkitController.onUpdateNodeForAnchor = (anchor) {
      if (isScanning && anchor is ARKitPlaneAnchor) {
        processPlaneSurface(anchor);
      }
    };

    // Gestione feature points
    arkitController.onUpdateNodeForAnchor = (anchor) {
      if (isScanning && anchor.identifier != null) {
        // Crea punti di scansione basati sugli anchor
        final randomOffset = vector.Vector3(
          (math.Random().nextDouble() - 0.5) * 0.1,
          (math.Random().nextDouble() - 0.5) * 0.1,
          (math.Random().nextDouble() - 0.5) * 0.1,
        );
        addScannedPoint(randomOffset);
      }
    };

    setState(() {
      scanStatus = 'LiDAR inizializzato - Inquadra l\'oggetto';
    });
  }

  void addScannedPoint(vector.Vector3 position) {
    scannedPoints.add(position);

    // Aggiungi visualizzazione del punto
    final node = ARKitNode(
      geometry: ARKitSphere(
        radius: 0.002,
        materials: [
          ARKitMaterial(diffuse: ARKitMaterialProperty.color(Colors.cyan)),
        ],
      ),
      position: position,
    );

    visualNodes.add(node);
    arkitController.add(node);

    // Aggiorna il conteggio
    if (scannedPoints.length % 10 == 0) {
      setState(() {
        scanStatus = 'Scansione in corso... ${scannedPoints.length} punti';
      });
    }
  }

  void processPlaneSurface(ARKitPlaneAnchor plane) {
    // Genera punti sulla superficie del piano rilevato
    final center = plane.center;
    final extent = plane.extent;

    // Crea una griglia di punti sul piano
    const gridResolution = 10;
    for (int i = 0; i < gridResolution; i++) {
      for (int j = 0; j < gridResolution; j++) {
        final x =
            center.x + (i - gridResolution / 2) * (extent.x / gridResolution);
        final y = center.y;
        final z =
            center.z + (j - gridResolution / 2) * (extent.z / gridResolution);

        final point = vector.Vector3(x, y, z);
        scannedPoints.add(point);

        // Aggiungi visualizzazione (solo alcuni punti per performance)
        if (scannedPoints.length % 5 == 0) {
          final node = ARKitNode(
            geometry: ARKitSphere(
              radius: 0.001,
              materials: [
                ARKitMaterial(
                  diffuse: ARKitMaterialProperty.color(Colors.green),
                ),
              ],
            ),
            position: point,
          );
          visualNodes.add(node);
          arkitController.add(node);
        }
      }
    }
  }

  void toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        scanStatus = 'Scansione in corso... Tocca per aggiungere punti';
        scannedPoints.clear();

        // Inizia la scansione automatica simulata
        startAutomaticScanning();
      } else {
        scanStatus =
            'Scansione completata - ${scannedPoints.length} punti acquisiti';
      }
    });
  }

  void startAutomaticScanning() {
    // Simula acquisizione automatica di punti
    if (!isScanning) return;

    Future.delayed(Duration(milliseconds: 100), () {
      if (isScanning) {
        // Genera punti casuali nell'area di fronte alla camera
        final random = math.Random();
        final point = vector.Vector3(
          (random.nextDouble() - 0.5) * 2.0,
          (random.nextDouble() - 0.5) * 2.0,
          -1.0 - random.nextDouble() * 2.0,
        );

        addScannedPoint(point);

        // Continua la scansione
        if (scannedPoints.length < 500) {
          startAutomaticScanning();
        } else {
          setState(() {
            isScanning = false;
            scanStatus = 'Scansione automatica completata';
          });
        }
      }
    });
  }

  void resetScan() {
    setState(() {
      isScanning = false;
      scanStatus = 'Pronto per la scansione';

      // Rimuovi tutti i nodi visuali
      for (var node in visualNodes) {
        arkitController.remove(node.name);
      }
      visualNodes.clear();
      scannedPoints.clear();
    });
  }

  Future<void> saveAndUploadScan() async {
    setState(() {
      isProcessing = true;
      scanStatus = 'Generazione file PLY...';
    });

    try {
      // Genera il file PLY
      final plyFile = await generatePLYFile();

      setState(() {
        scanStatus = 'Caricamento su Firebase...';
      });

      // Carica su Firebase Storage
      final downloadUrl = await uploadToFirebase(plyFile);

      setState(() {
        isProcessing = false;
        scanStatus = 'Caricamento completato!';
      });

      // Mostra dialogo di successo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Successo!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('La scansione è stata salvata con successo.'),
              SizedBox(height: 10),
              Text('Punti acquisiti: ${scannedPoints.length}'),
              SizedBox(height: 5),
              Text('File: scan_${DateTime.now().millisecondsSinceEpoch}.ply'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetScan();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isProcessing = false;
        scanStatus = 'Errore: ${e.toString()}';
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Errore'),
          content: Text(
            'Si è verificato un errore durante il salvataggio: ${e.toString()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<File> generatePLYFile() async {
    // Crea il contenuto del file PLY
    StringBuffer plyContent = StringBuffer();

    // Header PLY
    plyContent.writeln('ply');
    plyContent.writeln('format ascii 1.0');
    plyContent.writeln('element vertex ${scannedPoints.length}');
    plyContent.writeln('property float x');
    plyContent.writeln('property float y');
    plyContent.writeln('property float z');
    plyContent.writeln('property uchar red');
    plyContent.writeln('property uchar green');
    plyContent.writeln('property uchar blue');
    plyContent.writeln('end_header');

    // Aggiungi i vertici
    for (var point in scannedPoints) {
      // Aggiungi coordinate x, y, z e colore RGB (cyan per i punti scansionati)
      plyContent.writeln('${point.x} ${point.y} ${point.z} 0 255 255');
    }

    // Salva il file localmente
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/scan_$timestamp.ply');
    await file.writeAsString(plyContent.toString());

    return file;
  }

  Future<String> uploadToFirebase(File file) async {
    // Crea un riferimento univoco in Firebase Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('lidar_scans')
        .child('scan_$timestamp.ply');

    // Carica il file
    final uploadTask = await storageRef.putFile(file);

    // Ottieni l'URL di download
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Opzionale: elimina il file locale dopo il caricamento
    await file.delete();

    return downloadUrl;
  }
}
