import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils.dart';

class PlyViewerPage extends StatefulWidget {
  final String scanId;
  const PlyViewerPage({super.key, required this.scanId});

  @override
  State<PlyViewerPage> createState() => _PlyViewerPageState();
}

class _PlyViewerPageState extends State<PlyViewerPage> {
  late Future<String> _plyUrlFuture;

  @override
  void initState() {
    super.initState();
    _plyUrlFuture = _getPlyUrl();
  }

  Future<String> _getPlyUrl() async {
    try {
      // Usa il percorso dinamico
      final ref = FirebaseStorage.instance.ref(
        'comparisons/${widget.scanId}.ply',
      );
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Errore nel recuperare l'URL del file PLY: $e");
      throw Exception('Could not get model URL.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.backgroundColor;
    const cardColor = AppColors.cardBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        shadowColor: cardColor,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0.5,
        title: const Text('3D Comparison'),
      ),
      body: FutureBuilder<String>(
        future: _plyUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              color: AppColors.primary,
            )
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load model.'));
          }
          // Passiamo sia l'URL che lo scanId al nostro PlyViewer
          return PlyViewer(modelUrl: snapshot.data!, scanId: widget.scanId);
        },
      ),
    );
  }
}

class PlyViewer extends StatefulWidget {
  final String modelUrl;
  final String scanId; // Aggiunto scanId
  const PlyViewer({super.key, required this.modelUrl, required this.scanId});

  @override
  State<PlyViewer> createState() => _PlyViewerState();
}

class _PlyViewerState extends State<PlyViewer> {
  bool _isNativeLoading = true;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'ply_viewer';

    return Stack(
      alignment: Alignment.center,
      children: [
        UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (int id) async {
            final channel = MethodChannel('ply_viewer_$id');
            try {
              // --- MODIFICA: Passiamo una mappa con entrambi i valori ---
              await channel.invokeMethod('loadModel', {
                'url': widget.modelUrl,
                'scanId': widget.scanId,
              });
              if (mounted) {
                setState(() {
                  _isNativeLoading = false;
                });
              }
            } catch (e) {
              debugPrint("Errore dal lato nativo: $e");
            }
          },
        ),
        if (_isNativeLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
