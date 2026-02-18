import 'package:flutter/material.dart';
import 'package:ar_scan_kit_3d/scan_kit.dart';

void main() {
  runApp(const ScanKitExampleApp());
}

class ScanKitExampleApp extends StatelessWidget {
  const ScanKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanKit Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScanPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanKitController? _controller;
  bool _isScanning = false;
  int _vertexCount = 0;
  int _faceCount = 0;
  String _status = 'Ready';

  void _onViewCreated(ScanKitController controller) {
    _controller = controller;
    controller.meshStream.listen((mesh) {
      if (mounted) {
        setState(() {
          _vertexCount = mesh.totalVertexCount;
          _faceCount = mesh.totalFaceCount;
        });
      }
    });
  }

  Future<void> _startScanning() async {
    if (_controller == null) return;
    await _controller!.startScanning(const ScanKitConfiguration(
      mode: ScanMode.lidar,
      enableStreaming: true,
      updateFrequencyHz: 5,
    ));
    setState(() {
      _isScanning = true;
      _status = 'Scanning...';
    });
  }

  Future<void> _stopScanning() async {
    if (_controller == null) return;
    await _controller!.stopScanning();
    setState(() {
      _isScanning = false;
      _status = 'Stopped';
    });
  }

  Future<void> _exportOBJ() async {
    if (_controller == null) return;
    setState(() => _status = 'Exporting OBJ...');
    final path = await _controller!.exportMesh(
      ExportFormat.obj,
      '/tmp/scan_kit_export.obj',
    );
    setState(() => _status = 'Exported: $path');
  }

  Future<void> _exportGLB() async {
    if (_controller == null) return;
    setState(() => _status = 'Exporting GLB...');
    final path = await _controller!.exportMesh(
      ExportFormat.glb,
      '/tmp/scan_kit_export.glb',
    );
    setState(() => _status = 'Exported: $path');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ScanKit Demo')),
      body: Column(
        children: [
          Expanded(
            child: ScanKitView(onViewCreated: _onViewCreated),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Vertices: $_vertexCount | Faces: $_faceCount'),
                Text(_status),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isScanning ? null : _startScanning,
                      child: const Text('Start'),
                    ),
                    ElevatedButton(
                      onPressed: _isScanning ? _stopScanning : null,
                      child: const Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: _exportOBJ,
                      child: const Text('OBJ'),
                    ),
                    ElevatedButton(
                      onPressed: _exportGLB,
                      child: const Text('GLB'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
