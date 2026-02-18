# scan_kit

[![pub package](https://img.shields.io/pub/v/scan_kit.svg)](https://pub.dev/packages/scan_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/arkit/)

A Flutter plugin for real-time 3D scanning on iOS using Apple ARKit, with LiDAR and TrueDepth sensor support and OBJ/GLB export.

## Features

- **LiDAR scanning** — capture detailed 3D meshes using the rear LiDAR sensor
- **TrueDepth scanning** — scan using the front-facing TrueDepth camera
- **Real-time mesh streaming** — receive mesh updates at a configurable frequency (1–30 Hz)
- **Mesh classification** — identify surfaces as walls, floors, ceilings, tables, seats, windows, or doors
- **OBJ export** — export scanned meshes as Wavefront OBJ files
- **GLB export** — export scanned meshes as binary glTF files
- **On-demand snapshots** — capture the current mesh state at any time

## Requirements

| Requirement | Minimum |
|---|---|
| iOS | 15.0+ |
| Flutter | 3.10.0+ |
| Dart SDK | 3.11.0+ |

- **LiDAR mode** requires a device with a LiDAR sensor (iPhone 12 Pro and later Pro models, iPad Pro 2020+)
- **TrueDepth mode** requires a device with a TrueDepth camera (iPhone X and later)

## Installation

Add `scan_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  scan_kit: ^0.1.0
```

### iOS setup

Add a camera usage description to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera for 3D scanning.</string>
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:scan_kit/scan_kit.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanKitController? _controller;

  void _onViewCreated(ScanKitController controller) {
    _controller = controller;

    // Listen to real-time mesh updates
    controller.meshStream.listen((meshData) {
      print('Vertices: ${meshData.totalVertexCount}');
    });
  }

  Future<void> _startScan() async {
    await _controller?.startScanning(const ScanKitConfiguration(
      mode: ScanMode.lidar,
      enableClassification: true,
      updateFrequencyHz: 10,
    ));
  }

  Future<void> _stopAndExport() async {
    await _controller?.stopScanning();
    final path = await _controller?.exportMesh(
      ExportFormat.glb,
      '/path/to/output.glb',
    );
    print('Exported to: $path');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ScanKitView(onViewCreated: _onViewCreated)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _startScan, child: const Text('Start')),
            const SizedBox(width: 16),
            ElevatedButton(onPressed: _stopAndExport, child: const Text('Stop & Export')),
          ],
        ),
      ],
    );
  }
}
```

## API Reference

### Classes

| Class | Description |
|---|---|
| `ScanKitView` | A platform view widget that displays the AR camera feed |
| `ScanKitController` | Controls scanning, streaming, snapshots, and export |
| `ScanKitConfiguration` | Configuration for a scanning session |
| `ScanKitMeshData` | Container for a collection of mesh anchors |
| `ScanKitMeshAnchor` | A single mesh anchor with vertices, normals, faces, and classification |

### Enums

| Enum | Values |
|---|---|
| `ScanMode` | `lidar`, `trueDepth` |
| `ExportFormat` | `obj`, `glb` |
| `MeshClassification` | `none`, `wall`, `floor`, `ceiling`, `table`, `seat`, `window`, `door` |

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `mode` | `ScanMode` | `lidar` | Scanning mode to use |
| `enableStreaming` | `bool` | `true` | Whether to stream mesh updates in real time |
| `updateFrequencyHz` | `int` | `5` | Mesh update frequency in Hz (1–30) |
| `enableClassification` | `bool` | `true` | Whether to classify mesh surfaces |

## Export Formats

| Format | Extension | Description |
|---|---|---|
| OBJ | `.obj` | Wavefront OBJ — widely supported text-based format |
| GLB | `.glb` | Binary glTF — compact binary format for 3D applications |

## Example

See the [example](example/) directory for a complete sample app.

## License

MIT — see [LICENSE](LICENSE) for details.
