import 'scan_mode.dart';

/// Configuration for a scanning session.
///
/// Controls which sensor to use, whether to stream mesh updates,
/// the update frequency, and whether to classify surfaces.
class ScanKitConfiguration {
  /// The scanning mode (LiDAR or TrueDepth).
  final ScanMode mode;

  /// Whether to stream mesh updates in real time. Defaults to `true`.
  final bool enableStreaming;

  /// Mesh update frequency in Hz (1–30). Defaults to `5`.
  final int updateFrequencyHz;

  /// Whether to classify detected surfaces. Defaults to `true`.
  final bool enableClassification;

  const ScanKitConfiguration({
    this.mode = ScanMode.lidar,
    this.enableStreaming = true,
    this.updateFrequencyHz = 5,
    this.enableClassification = true,
  }) : assert(updateFrequencyHz >= 1 && updateFrequencyHz <= 30);

  Map<String, dynamic> toMap() => {
        'mode': mode.name,
        'enableStreaming': enableStreaming,
        'updateFrequencyHz': updateFrequencyHz,
        'enableClassification': enableClassification,
      };
}
