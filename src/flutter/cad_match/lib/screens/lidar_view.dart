import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class LidarPoint {
  final v.Vector3 position;
  final int r;
  final int g;
  final int b;

  const LidarPoint({
    required this.position,
    required this.r,
    required this.g,
    required this.b,
  });
}

typedef LidarPointsCallback = void Function(List<LidarPoint> pts);

class LidarView extends StatefulWidget {
  final LidarPointsCallback onPoints;
  const LidarView({super.key, required this.onPoints});

  @override
  LidarViewState createState() => LidarViewState();
}

class LidarViewState extends State<LidarView> {
  MethodChannel? _methods;
  StreamSubscription? _sub;
  DateTime? lastPointsAt;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onCreated(int id) async {
    _methods = MethodChannel('devnut.lidar/methods_$id');
    final stream = EventChannel(
      'devnut.lidar/points_$id',
    ).receiveBroadcastStream();

    _sub = stream.listen((data) {
      try {
        // Gestione corretta dei tipi dal canale
        Float32List f32;
        if (data is Float32List) {
          f32 = data;
        } else if (data is Uint8List) {
          f32 = data.buffer.asFloat32List();
        } else if (data is ByteData) {
          f32 = data.buffer.asFloat32List();
        } else {
          if (kDebugMode) {
            debugPrint('Unexpected lidar payload type: ${data.runtimeType}');
          }
          return;
        }

        final pts = _toPoints(f32);
        if (pts.isNotEmpty) lastPointsAt = DateTime.now();
        widget.onPoints(pts);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Lidar decode error: $e\n$st');
        }
      }
    });
  }

  List<LidarPoint> _toPoints(Float32List buf) {
    final out = <LidarPoint>[];
    for (var i = 0; i + 5 < buf.length; i += 6) {
      final pos = v.Vector3(buf[i], buf[i + 1], buf[i + 2]);
      final r = _channel(buf[i + 3]);
      final g = _channel(buf[i + 4]);
      final b = _channel(buf[i + 5]);
      out.add(LidarPoint(position: pos, r: r, g: g, b: b));
    }
    return out;
  }

  Future<void> start() async => _methods?.invokeMethod('start');
  Future<void> stop() async => _methods?.invokeMethod('stop');
  Future<void> reset() async => _methods?.invokeMethod('reset');

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'devnut.lidar_view',
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  int _channel(double value) {
    var normalized = value;
    if (normalized.isNaN) normalized = 0.0;
    if (normalized < 0.0) normalized = 0.0;
    if (normalized > 1.0) normalized = 1.0;
    final rounded = (normalized * 255.0).round();
    if (rounded < 0) return 0;
    if (rounded > 255) return 255;
    return rounded;
  }
}
