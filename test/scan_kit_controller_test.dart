import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_scan_kit_3d/src/scan_kit_controller.dart';
import 'package:ar_scan_kit_3d/src/models/scan_config.dart';
import 'package:ar_scan_kit_3d/src/models/scan_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanKitController', () {
    late ScanKitController controller;
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];

      // Mock the view method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit/view_1'),
        (MethodCall call) async {
          methodCalls.add(call);
          switch (call.method) {
            case 'startScanning':
              return null;
            case 'stopScanning':
              return null;
            case 'getSnapshot':
              return {
                'anchors': <Map<String, dynamic>>[],
              };
            case 'dispose':
              return null;
            default:
              return null;
          }
        },
      );

      // Mock the event channel (no-op for unit tests)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit/mesh_stream_1',
            StandardMethodCodec()),
        (MethodCall call) async {
          return null;
        },
      );

      controller = ScanKitController(1);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit/view_1'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit/mesh_stream_1',
            StandardMethodCodec()),
        null,
      );
    });

    test('startScanning sends correct method call', () async {
      const config = ScanKitConfiguration(
        mode: ScanMode.lidar,
        enableStreaming: true,
        updateFrequencyHz: 10,
      );

      await controller.startScanning(config);

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'startScanning');
      final args = methodCalls[0].arguments as Map;
      expect(args['mode'], 'lidar');
      expect(args['updateFrequencyHz'], 10);
    });

    test('stopScanning sends correct method call', () async {
      await controller.stopScanning();
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'stopScanning');
    });

    test('getSnapshot returns ScanKitMeshData', () async {
      final snapshot = await controller.getSnapshot();
      expect(snapshot.isEmpty, true);
      expect(methodCalls.last.method, 'getSnapshot');
    });

    test('dispose sends correct method call', () async {
      await controller.dispose();
      expect(methodCalls.any((c) => c.method == 'dispose'), true);
    });
  });

  group('ScanKitController static methods', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit'),
        (MethodCall call) async {
          switch (call.method) {
            case 'isLiDARSupported':
              return true;
            case 'isTrueDepthSupported':
              return false;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.jorgeferrarice.scankit'),
        null,
      );
    });

    test('isLiDARSupported returns platform result', () async {
      final result = await ScanKitController.isLiDARSupported();
      expect(result, true);
    });

    test('isTrueDepthSupported returns platform result', () async {
      final result = await ScanKitController.isTrueDepthSupported();
      expect(result, false);
    });
  });
}
