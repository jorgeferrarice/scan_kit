import 'package:flutter_test/flutter_test.dart';
import 'package:scan_kit/src/scan_kit_platform.dart';
import 'package:scan_kit/src/models/mesh_data.dart';

void main() {
  group('ScanKitPlatform', () {
    test('viewChannel creates channel with correct name', () {
      final channel = ScanKitPlatform.viewChannel(42);
      expect(channel.name, 'dev.jorgeferrarice.scankit/view_42');
    });

    test('meshStreamChannel creates channel with correct name', () {
      final channel = ScanKitPlatform.meshStreamChannel(7);
      expect(channel.name, 'dev.jorgeferrarice.scankit/mesh_stream_7');
    });

    test('deserializeMeshData from Map', () {
      final result = ScanKitPlatform.deserializeMeshData({
        'anchors': <Map<String, dynamic>>[],
      });
      expect(result, isA<ScanKitMeshData>());
      expect(result.isEmpty, true);
    });

    test('deserializeMeshData from non-Map returns empty', () {
      final result = ScanKitPlatform.deserializeMeshData('invalid');
      expect(result.isEmpty, true);
    });
  });
}
