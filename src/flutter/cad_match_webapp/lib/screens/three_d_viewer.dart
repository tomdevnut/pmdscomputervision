import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import '../shared_utils.dart';

class ThreeViewerPage extends StatefulWidget {
  final String id; 

  const ThreeViewerPage({super.key, required this.id});

  @override
  State<ThreeViewerPage> createState() => _ThreeViewerPageState();
}

class _ThreeViewerPageState extends State<ThreeViewerPage> {
  final String _viewId = 'three-viewer-iframe';
  late html.IFrameElement _iframeElement;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    _iframeElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement,
    );

    html.window.onMessage.listen((event) {
      if (event.data is Map && event.data['status'] == 'ready') {
        fetchPlyUrl();
      }
    });

    _iframeElement.src =
        '${html.window.location.origin}/viewer/model_viewer.html';

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchPlyUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref('comparisons/${widget.id}.ply');
      final url = await ref.getDownloadURL();
      _iframeElement.contentWindow?.postMessage({'fileUrl': url}, '*');
    } catch (e) {
      setState(() {
        error = 'Errore nel recupero del file: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: const Center(child: CircularProgressIndicator(
          color: AppColors.primary,
        )),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.red),)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          children: [
            buildTopBar(context, title: '3D VIEWER'),
            Expanded(child: HtmlElementView(viewType: _viewId)),
          ],
        ),
      ),
    );
  }
}
