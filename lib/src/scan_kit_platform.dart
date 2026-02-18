import 'dart:async';

import 'package:flutter/services.dart';

import 'models/mesh_data.dart';

class ScanKitPlatform {
  static const _globalChannel = MethodChannel('dev.jorgeferrarice.scankit');

  static Future<bool> isLiDARSupported() async {
    final result = await _globalChannel.invokeMethod<bool>('isLiDARSupported');
    return result ?? false;
  }

  static Future<bool> isTrueDepthSupported() async {
    final result =
        await _globalChannel.invokeMethod<bool>('isTrueDepthSupported');
    return result ?? false;
  }

  static MethodChannel viewChannel(int viewId) {
    return MethodChannel('dev.jorgeferrarice.scankit/view_$viewId');
  }

  static EventChannel meshStreamChannel(int viewId) {
    return EventChannel('dev.jorgeferrarice.scankit/mesh_stream_$viewId');
  }

  static ScanKitMeshData deserializeMeshData(dynamic event) {
    if (event is Map) {
      return ScanKitMeshData.fromMap(Map<String, dynamic>.from(event));
    }
    return const ScanKitMeshData(anchors: []);
  }
}
