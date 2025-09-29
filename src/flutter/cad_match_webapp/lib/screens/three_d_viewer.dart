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
  late String _viewId;
  late web.HTMLIFrameElement _iframeElement;

  late web.EventListener _messageListener;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    _viewId = 'iframe-${widget.id}-${DateTime.now().millisecondsSinceEpoch}';

    _iframeElement =
        web.document.createElement('iframe') as web.HTMLIFrameElement
          ..style.setProperty('border', 'none')
          ..style.setProperty('width', '100%')
          ..style.setProperty('height', '100%');

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement,
    );

    _messageListener = (web.Event event) {
      final messageEvent = event as web.MessageEvent;
      final data = messageEvent.data;

      if (data.isA<JSObject>()) {
        final status = (data.dartify() as Map)['status'];
        if (status == 'ready') {
          fetchPlyUrl();
        }
      }
    }.toJS;
    web.window.addEventListener('message', _messageListener);

    _iframeElement.src =
        '${web.window.location.origin}/viewer/model_viewer.html?v=${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchPlyUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref('comparisons/${widget.id}.ply');
      final url = await ref.getDownloadURL();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _iframeElement.contentWindow?.postMessage(
            {'fileUrl': url}.jsify(),
            '*'.toJS,
          );

          setState(() {
            loading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error while fetching PLY URL: $e';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    web.window.removeEventListener('message', _messageListener);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            children: [
              buildTopBar(context, title: '3D VIEWER'),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
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
