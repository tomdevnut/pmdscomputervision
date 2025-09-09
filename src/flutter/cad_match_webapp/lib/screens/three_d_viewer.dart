import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

import '../shared_utils.dart';

class ThreeViewerPage extends StatefulWidget {
  final String id;

  const ThreeViewerPage({super.key, required this.id});

  @override
  State<ThreeViewerPage> createState() => _ThreeViewerPageState();
}

class _ThreeViewerPageState extends State<ThreeViewerPage> {
  final String _viewId = 'three-viewer-iframe';
  late web.HTMLIFrameElement _iframeElement;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    _iframeElement =
        web.document.createElement('iframe') as web.HTMLIFrameElement
          ..style.setProperty('border', 'none')
          ..style.setProperty('width', '100%')
          ..style.setProperty('height', '100%');

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement,
    );

    web.window.addEventListener(
      'message',
      (web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final data = messageEvent.data;

        if (data.isA<JSObject>()) {
          final status = (data.dartify() as Map)['status'];
          if (status == 'ready') {
            fetchPlyUrl();
          }
        }
      }.toJS,
    );

    _iframeElement.src =
        '${web.window.location.origin}/viewer/model_viewer.html';

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchPlyUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref('comparisons/${widget.id}.ply');
      final url = await ref.getDownloadURL();
      final jsObject = {'fileUrl': url}.jsify();
      _iframeElement.contentWindow?.postMessage(jsObject, '*'.toJS);
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
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
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
