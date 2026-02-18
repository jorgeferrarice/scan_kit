/// A Flutter plugin for real-time 3D scanning on iOS using Apple ARKit.
///
/// Supports LiDAR and TrueDepth sensors with real-time mesh streaming
/// and OBJ/GLB export.
///
/// Usage:
/// ```dart
/// import 'package:ar_scan_kit_3d/ar_scan_kit_3d.dart';
/// ```
library;

export 'src/scan_kit_view.dart';
export 'src/scan_kit_controller.dart';
export 'src/models/mesh_data.dart';
export 'src/models/scan_mode.dart';
export 'src/models/scan_config.dart';
export 'src/models/export_format.dart';
