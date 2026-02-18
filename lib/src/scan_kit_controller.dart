import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'models/export_format.dart';
import 'models/mesh_data.dart';
import 'models/scan_config.dart';
import 'exporters/obj_exporter.dart';
import 'exporters/glb_exporter.dart';
import 'scan_kit_platform.dart';

/// Controls a scanning session initiated by [ScanKitView].
///
/// Provides methods to start/stop scanning, stream mesh data in real time,
/// capture on-demand snapshots, and export meshes to OBJ or GLB files.
///
/// Obtain an instance via the [ScanKitView.onViewCreated] callback.
/// Call [dispose] when the controller is no longer needed.
class ScanKitController {
  final int _viewId;
  late final MethodChannel _channel;
  late final EventChannel _eventChannel;
  StreamSubscription? _meshSubscription;
  final _meshStreamController = StreamController<ScanKitMeshData>.broadcast();
  ScanKitMeshData _latestMesh = const ScanKitMeshData(anchors: []);

  ScanKitController(this._viewId) {
    _channel = ScanKitPlatform.viewChannel(_viewId);
    _eventChannel = ScanKitPlatform.meshStreamChannel(_viewId);
    _meshSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final mesh = ScanKitPlatform.deserializeMeshData(event);
      _latestMesh = mesh;
      _meshStreamController.add(mesh);
    });
  }

  /// A broadcast stream of [ScanKitMeshData] received from the native scanner.
  ///
  /// Updates are emitted at the frequency specified by
  /// [ScanKitConfiguration.updateFrequencyHz] when streaming is enabled.
  Stream<ScanKitMeshData> get meshStream => _meshStreamController.stream;

  /// Returns `true` if the device has a LiDAR sensor.
  static Future<bool> isLiDARSupported() => ScanKitPlatform.isLiDARSupported();

  /// Returns `true` if the device has a TrueDepth camera.
  static Future<bool> isTrueDepthSupported() =>
      ScanKitPlatform.isTrueDepthSupported();

  /// Starts a scanning session with the given [config].
  ///
  /// The AR session begins capturing mesh data using the sensor specified
  /// by [ScanKitConfiguration.mode].
  Future<void> startScanning(ScanKitConfiguration config) async {
    await _channel.invokeMethod('startScanning', config.toMap());
  }

  /// Stops the current scanning session.
  ///
  /// Mesh streaming is halted but the last captured mesh is retained.
  Future<void> stopScanning() async {
    await _channel.invokeMethod('stopScanning');
  }

  /// Captures and returns a snapshot of the current mesh state.
  Future<ScanKitMeshData> getSnapshot() async {
    final result = await _channel.invokeMethod<Map>('getSnapshot');
    if (result != null) {
      return ScanKitMeshData.fromMap(Map<String, dynamic>.from(result));
    }
    return const ScanKitMeshData(anchors: []);
  }

  /// Exports the current mesh to a file at [path] in the given [format].
  ///
  /// If no mesh data has been streamed yet, a snapshot is captured first.
  /// Returns the output file path.
  Future<String> exportMesh(ExportFormat format, String path) async {
    final mesh = _latestMesh.isEmpty ? await getSnapshot() : _latestMesh;

    switch (format) {
      case ExportFormat.obj:
        final content = ObjExporter.export(mesh);
        await File(path).writeAsString(content);
      case ExportFormat.glb:
        final bytes = GlbExporter.export(mesh);
        await File(path).writeAsBytes(bytes);
    }
    return path;
  }

  /// Releases resources held by this controller.
  ///
  /// Must be called when the controller is no longer needed.
  Future<void> dispose() async {
    await _meshSubscription?.cancel();
    await _meshStreamController.close();
    await _channel.invokeMethod('dispose');
  }
}
