import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:scan_kit/src/exporters/obj_exporter.dart';
import 'package:scan_kit/src/models/mesh_data.dart';

void main() {
  group('ObjExporter', () {
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

    test('exports single triangle with identity transform', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [0, 0, 0, 1, 0, 0, 0, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final obj = ObjExporter.export(mesh);
      final lines = obj.split('\n').where((l) => l.isNotEmpty).toList();

      // Count vertex and face lines
      final vLines = lines.where((l) => l.startsWith('v ')).toList();
      final vnLines = lines.where((l) => l.startsWith('vn ')).toList();
      final fLines = lines.where((l) => l.startsWith('f ')).toList();

      expect(vLines.length, 3);
      expect(vnLines.length, 3);
      expect(fLines.length, 1);

      // Face indices should be 1-based
      expect(fLines[0], 'f 1//1 2//2 3//3');
    });

    test('applies transform to vertices', () {
      // Translation by (10, 20, 30)
      final transform = Matrix4.identity()..setTranslation(Vector3(10, 20, 30));

      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          vertices: [0, 0, 0],
          normals: [0, 0, 1],
          faces: [],
          transform: transform,
        ),
      ]);

      final obj = ObjExporter.export(mesh);
      final vLine =
          obj.split('\n').firstWhere((l) => l.startsWith('v '));

      expect(vLine, contains('10.000000'));
      expect(vLine, contains('20.000000'));
      expect(vLine, contains('30.000000'));
    });

    test('multi-anchor index offsets are correct', () {
      final mesh = ScanKitMeshData(anchors: [
        makeAnchor(
          id: 'a1',
          vertices: [0, 0, 0, 1, 0, 0, 0, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
        makeAnchor(
          id: 'a2',
          vertices: [2, 0, 0, 3, 0, 0, 2, 1, 0],
          normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
          faces: [0, 1, 2],
        ),
      ]);

      final obj = ObjExporter.export(mesh);
      final fLines =
          obj.split('\n').where((l) => l.startsWith('f ')).toList();

      expect(fLines.length, 2);
      // First anchor: 1-based from 1
      expect(fLines[0], 'f 1//1 2//2 3//3');
      // Second anchor: offset by 3 vertices
      expect(fLines[1], 'f 4//4 5//5 6//6');
    });

    test('exports empty mesh without errors', () {
      final mesh = ScanKitMeshData(anchors: []);
      final obj = ObjExporter.export(mesh);

      expect(obj, contains('# Vertices: 0'));
      expect(obj, contains('# Faces: 0'));
    });
  });
}
