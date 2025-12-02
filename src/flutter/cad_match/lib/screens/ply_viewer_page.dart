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
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.buttonText,
        title: const Text(
          '3D Comparison',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: FutureBuilder<String>(
              future: _plyUrlFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Failed to load 3D model.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return PlyViewer(
                  modelUrl: snapshot.data!,
                  scanId: widget.scanId,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PlyViewer extends StatefulWidget {
  final String modelUrl;
  final String scanId;
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
              if (mounted) {
                setState(() {
                  _isNativeLoading = false;
                });
              }
            }
          },
        ),
        if (_isNativeLoading)
          Container(
            color: AppColors.backgroundColor.withAlpha(128),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
