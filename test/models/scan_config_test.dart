import 'package:flutter_test/flutter_test.dart';
import 'package:ar_scan_kit_3d/src/models/scan_config.dart';
import 'package:ar_scan_kit_3d/src/models/scan_mode.dart';

void main() {
  group('ScanKitConfiguration', () {
    test('default values', () {
      const config = ScanKitConfiguration();
      expect(config.mode, ScanMode.lidar);
      expect(config.enableStreaming, true);
      expect(config.updateFrequencyHz, 5);
      expect(config.enableClassification, true);
    });

    test('toMap serializes correctly', () {
      const config = ScanKitConfiguration(
        mode: ScanMode.trueDepth,
        enableStreaming: false,
        updateFrequencyHz: 10,
        enableClassification: false,
      );

      final map = config.toMap();
      expect(map['mode'], 'trueDepth');
      expect(map['enableStreaming'], false);
      expect(map['updateFrequencyHz'], 10);
      expect(map['enableClassification'], false);
    });

    test('toMap with lidar mode', () {
      const config = ScanKitConfiguration(mode: ScanMode.lidar);
      expect(config.toMap()['mode'], 'lidar');
    });

    test('assertion fails for frequency below 1', () {
      expect(
        () => ScanKitConfiguration(updateFrequencyHz: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assertion fails for frequency above 30', () {
      expect(
        () => ScanKitConfiguration(updateFrequencyHz: 31),
        throwsA(isA<AssertionError>()),
      );
    });

    test('boundary frequencies are valid', () {
      expect(
        () => const ScanKitConfiguration(updateFrequencyHz: 1),
        returnsNormally,
      );
      expect(
        () => const ScanKitConfiguration(updateFrequencyHz: 30),
        returnsNormally,
      );
    });
  });
}
