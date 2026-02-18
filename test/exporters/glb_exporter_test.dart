import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ar_scan_kit_3d/src/exporters/glb_exporter.dart';
import 'package:ar_scan_kit_3d/src/models/mesh_data.dart';

void main() {
  group('GlbExporter', () {
    ScanKitMeshAnchor makeAnchor({
      String id = 'test',
      List<double> vertices = const [],
      List<double> normals = const [],
      List<int> faces = const [],
      Matrix4? transform,
    }) {
      return ScanKitMeshAnchor(
        identifier: id,
        transform: transform ?? Matrix4.identity(),
        vertices: Float32List.fromList(vertices),
        normals: Float32List.fromList(normals),
        faces: Uint32List.fromList(faces),
      );
    }

    test('GLB header has correct magic and version', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [0, 0, 0, 1, 0, 0, 0, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final bytes = GlbExporter.export(mesh);
      final byteData = ByteData.sublistView(bytes);

      // Magic: glTF
      expect(byteData.getUint32(0, Endian.little), 0x46546C67);
      // Version: 2
      expect(byteData.getUint32(4, Endian.little), 2);
      // Total length matches actual bytes
      expect(byteData.getUint32(8, Endian.little), bytes.length);
    });

    test('JSON chunk is valid JSON', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [0, 0, 0, 1, 0, 0, 0, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final bytes = GlbExporter.export(mesh);
      final byteData = ByteData.sublistView(bytes);

      // JSON chunk header
      final jsonChunkLength = byteData.getUint32(12, Endian.little);
      final jsonChunkType = byteData.getUint32(16, Endian.little);
      expect(jsonChunkType, 0x4E4F534A); // "JSON"

      // Extract and parse JSON
      final jsonBytes = bytes.sublist(20, 20 + jsonChunkLength);
      final jsonString = utf8.decode(jsonBytes).trimRight();
      final gltf = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(gltf['asset']['version'], '2.0');
      expect(gltf['meshes'], isNotEmpty);
      expect(gltf['accessors'], hasLength(3));
      expect(gltf['bufferViews'], hasLength(3));
    });

    test('buffer sizes match expected data', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [0, 0, 0, 1, 0, 0, 0, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final bytes = GlbExporter.export(mesh);
      final byteData = ByteData.sublistView(bytes);

      // Parse JSON to check buffer sizes
      final jsonChunkLength = byteData.getUint32(12, Endian.little);
      final jsonBytes = bytes.sublist(20, 20 + jsonChunkLength);
      final gltf =
          jsonDecode(utf8.decode(jsonBytes).trimRight()) as Map<String, dynamic>;

      // 3 faces * 3 indices * 4 bytes = 12 bytes for indices
      // 3 vertices * 3 floats * 4 bytes = 36 bytes for positions
      // 3 vertices * 3 floats * 4 bytes = 36 bytes for normals
      // Total: 84 bytes
      final totalByteLength = gltf['buffers'][0]['byteLength'] as int;
      expect(totalByteLength, 84);
    });

    test('exports empty mesh without errors', () {
      final mesh = ScanKitMeshData(anchors: []);
      final bytes = GlbExporter.export(mesh);

      final byteData = ByteData.sublistView(bytes);
      expect(byteData.getUint32(0, Endian.little), 0x46546C67);
      expect(byteData.getUint32(4, Endian.little), 2);
    });

    test('vertex data can be re-extracted from binary chunk', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final bytes = GlbExporter.export(mesh);
      final byteData = ByteData.sublistView(bytes);

      // Find BIN chunk
      final jsonChunkLength = byteData.getUint32(12, Endian.little);
      final binChunkOffset = 20 + jsonChunkLength;
      final binChunkType =
          byteData.getUint32(binChunkOffset + 4, Endian.little);
      expect(binChunkType, 0x004E4942); // "BIN\0"

      // Indices are first: 3 indices * 4 bytes = 12 bytes
      final binDataOffset = binChunkOffset + 8;
      // Positions start after indices
      final positionsOffset = binDataOffset + 12;
      final positions = Float32List.sublistView(
        bytes.buffer.asByteData(),
        positionsOffset,
        positionsOffset + 36,
      );

      expect(positions[0], closeTo(1.0, 0.001));
      expect(positions[1], closeTo(2.0, 0.001));
      expect(positions[2], closeTo(3.0, 0.001));
      expect(positions[3], closeTo(4.0, 0.001));
      expect(positions[7], closeTo(8.0, 0.001));
    });
  });
}
