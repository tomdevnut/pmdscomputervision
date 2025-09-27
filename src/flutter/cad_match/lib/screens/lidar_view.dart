import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as v;

typedef LidarPointsCallback = void Function(List<v.Vector3> pts);

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

        final pts = _toVec3(f32);
        if (pts.isNotEmpty) lastPointsAt = DateTime.now();
        widget.onPoints(pts);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Lidar decode error: $e\n$st');
        }
      }
    });
  }

  List<v.Vector3> _toVec3(Float32List buf) {
    final out = <v.Vector3>[];
    for (var i = 0; i + 2 < buf.length; i += 3) {
      out.add(v.Vector3(buf[i], buf[i + 1], buf[i + 2]));
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
}
