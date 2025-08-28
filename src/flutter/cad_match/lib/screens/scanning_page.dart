// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:arkit_plugin/arkit_plugin.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/services.dart';

// class ScanningPage extends StatefulWidget {
//   const ScanningPage({super.key});

//   @override
//   State<ScanningPage> createState() => _ScanningPageState();
// }

// class _ScanningPageState extends State<ScanningPage> {
//   ARKitController? _arKitController;
//   bool _isScanning = false;
//   String _statusMessage = 'Ready to scan.';
//   final List<ARKitNode> _nodes = [];
  
//   // MethodChannel per comunicare con il codice nativo iOS
//   static const platform = MethodChannel('com.example.flutter_scanning_app/scanner');

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _arKitController?.dispose();
//     super.dispose();
//   }

//   // Questo metodo viene chiamato quando la sessione ARKit è pronta.
//   void onARKitViewCreated(ARKitController arKitController) {
//     _arKitController = arKitController;
//     // Ascolta gli aggiornamenti della sessione ARKit.
//     _arKitController!.onAddNodeForAnchor = _handleAddAnchor;
//   }

//   // Aggiunge un nodo per ogni ancora (anchor) rilevata, come un piano.
//   void _handleAddAnchor(ARKitAnchor anchor) {
//     if (anchor is ARKitPlaneAnchor) {
//       final node = ARKitNode(
//         geometry: ARKitPlane(
//           width: anchor.extent.x,
//           height: anchor.extent.z,
//           materials: [
//             ARKitMaterial(
//               diffuse: ARKitMaterialProperty(color: Colors.white.withOpacity(0.5)),
//               transparency: 0.5,
//             )
//           ],
//         ),
//         position: vector.Vector3(anchor.transform.columns[3].x, 0, anchor.transform.columns[3].z),
//         rotation: vector.Vector4(1, 0, 0, -0.5 * 3.1415926535),
//       );
//       _arKitController!.add(node);
//       _nodes.add(node);
//     }
//   }

//   // Avvia la scansione LiDAR.
//   void _startScanning() {
//     setState(() {
//       _isScanning = true;
//       _statusMessage = 'Scanning in progress... Move the phone slowly.';
//     });
//     // Inizia la sessione ARKit.
//     _arKitController?.setupSession(
//       configuration: ARKitWorldTrackingConfiguration(
//         planeDetection: ARKitPlaneDetection.horizontal,
//       ),
//     );
//   }

//   // Ferma la scansione e salva i dati.
//   void _stopAndSaveScanning() async {
//     setState(() {
//       _isScanning = false;
//       _statusMessage = 'Saving scan data...';
//     });
    
//     _arKitController?.pause();
    
//     // Chiamata al metodo nativo per il salvataggio
//     try {
//       final String? result = await platform.invokeMethod('saveARData');
//       if (result != null) {
//         setState(() {
//           _statusMessage = 'Scan saved successfully to: $result';
//         });
//       } else {
//         setState(() {
//           _statusMessage = 'Error: Failed to save scan data.';
//         });
//       }
//     } on PlatformException catch (e) {
//       setState(() {
//         _statusMessage = "Error: '${e.message}'.";
//       });
//     }

//     _arKitController?.removeNodes(_nodes);
//     _nodes.clear();
//   }

//   // Resetta la scansione.
//   void _resetScanning() {
//     setState(() {
//       _isScanning = false;
//       _statusMessage = 'Scanning reset. Press Start to begin.';
//     });
//     _arKitController?.pause();
//     _arKitController?.removeNodes(_nodes);
//     _nodes.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Vista della sessione AR
//             ARKitSceneView(
//               onARKitViewCreated: onARKitViewCreated,
//               // Le opzioni di debug sono utili per visualizzare
//               // i punti della nuvola e i piani rilevati.
//               showFeaturePoints: true,
//               showWorldOrigin: true,
//               showStatistics: true,
//             ),
//             // UI sovrapposta alla vista AR
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Spazio per il tuo futuro design (es. barra superiore)
//                   const Spacer(),
//                   // Messaggio di stato
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       _statusMessage,
//                       style: const TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   // Pulsanti di controllo
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       _isScanning
//                           ? IconButton(
//                               icon: const Icon(Icons.stop_circle, color: Colors.red, size: 60),
//                               onPressed: _stopAndSaveScanning,
//                               tooltip: 'Stop and Save',
//                             )
//                           : IconButton(
//                               icon: const Icon(Icons.play_circle_filled, color: Colors.green, size: 60),
//                               onPressed: _startScanning,
//                               tooltip: 'Start Scanning',
//                             ),
//                       if (!_isScanning)
//                         IconButton(
//                           icon: const Icon(Icons.refresh, color: Colors.white, size: 40),
//                           onPressed: _resetScanning,
//                           tooltip: 'Cancel',
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
