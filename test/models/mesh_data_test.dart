import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ar_scan_kit_3d/src/models/mesh_data.dart';

void main() {
  group('ScanKitMeshAnchor', () {
    test('fromMap deserializes typed data correctly', () {
      // A triangle: 3 vertices, 3 normals, 1 face
      final vertices = Float32List.fromList([
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
      ]);
      final normals = Float32List.fromList([
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
      ]);
      final faces = Uint32List.fromList([0, 1, 2]);
      final transform = Float64List.fromList([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

      final anchor = ScanKitMeshAnchor.fromMap({
        'identifier': 'test-anchor-1',
        'transform': transform,
        'vertices': vertices,
        'normals': normals,
        'faces': faces,
        'classification': 1, // wall
      });

      expect(anchor.identifier, 'test-anchor-1');
      expect(anchor.vertexCount, 3);
      expect(anchor.faceCount, 1);
      expect(anchor.classification, MeshClassification.wall);
      expect(anchor.vertices[0], 0.0);
      expect(anchor.vertices[3], 1.0);
      expect(anchor.faces[0], 0);
      expect(anchor.faces[1], 1);
      expect(anchor.faces[2], 2);
    });

    test('fromMap handles empty mesh', () {
      final anchor = ScanKitMeshAnchor.fromMap({
        'identifier': 'empty',
        'vertices': Float32List(0),
        'normals': Float32List(0),
        'faces': Uint32List(0),
      });

      expect(anchor.vertexCount, 0);
      expect(anchor.faceCount, 0);
      expect(anchor.classification, MeshClassification.none);
    });

    test('fromMap handles single vertex', () {
      final anchor = ScanKitMeshAnchor.fromMap({
        'identifier': 'single',
        'vertices': Float32List.fromList([1.0, 2.0, 3.0]),
        'normals': Float32List.fromList([0.0, 1.0, 0.0]),
        'faces': Uint32List(0),
      });

      expect(anchor.vertexCount, 1);
      expect(anchor.faceCount, 0);
      expect(anchor.vertices[0], 1.0);
      expect(anchor.vertices[1], 2.0);
      expect(anchor.vertices[2], 3.0);
    });

    test('fromMap handles missing fields gracefully', () {
      final anchor = ScanKitMeshAnchor.fromMap({});

      expect(anchor.identifier, '');
      expect(anchor.vertexCount, 0);
      expect(anchor.faceCount, 0);
    });

    test('fromMap handles List types (non-typed)', () {
      final anchor = ScanKitMeshAnchor.fromMap({
        'identifier': 'list-types',
        'vertices': [1.0, 2.0, 3.0],
        'normals': [0.0, 1.0, 0.0],
        'faces': [0, 1, 2],
        'transform': [
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ],
      });

      expect(anchor.vertexCount, 1);
      expect(anchor.vertices[0], 1.0);
    });
  });

  group('ScanKitMeshData', () {
    test('fromMap deserializes multiple anchors', () {
      final meshData = ScanKitMeshData.fromMap({
        'anchors': [
          {
            'identifier': 'a1',
            'vertices': Float32List.fromList([0, 0, 0, 1, 0, 0, 0, 1, 0]),
            'normals': Float32List.fromList([0, 0, 1, 0, 0, 1, 0, 0, 1]),
            'faces': Uint32List.fromList([0, 1, 2]),
          },
          {
            'identifier': 'a2',
            'vertices': Float32List.fromList([2, 0, 0, 3, 0, 0, 2, 1, 0]),
            'normals': Float32List.fromList([0, 0, 1, 0, 0, 1, 0, 0, 1]),
            'faces': Uint32List.fromList([0, 1, 2]),
          },
        ],
      });

      expect(meshData.anchors.length, 2);
      expect(meshData.totalVertexCount, 6);
      expect(meshData.totalFaceCount, 2);
      expect(meshData.isEmpty, false);
    });

    test('fromMap handles empty anchors list', () {
      final meshData = ScanKitMeshData.fromMap({'anchors': []});
      expect(meshData.isEmpty, true);
      expect(meshData.totalVertexCount, 0);
      expect(meshData.totalFaceCount, 0);
    });

    test('fromMap handles missing anchors key', () {
      final meshData = ScanKitMeshData.fromMap({});
      expect(meshData.isEmpty, true);
    });
  });
}
