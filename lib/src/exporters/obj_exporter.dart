import 'package:vector_math/vector_math_64.dart';

import '../models/mesh_data.dart';

class ObjExporter {
  static String export(ScanKitMeshData meshData) {
    final buffer = StringBuffer();
    buffer.writeln('# ScanKit OBJ Export');
    buffer.writeln('# Vertices: ${meshData.totalVertexCount}');
    buffer.writeln('# Faces: ${meshData.totalFaceCount}');
    buffer.writeln();

    int vertexOffset = 0;

    for (final anchor in meshData.anchors) {
      buffer.writeln('# Anchor: ${anchor.identifier}');

      final vertices = anchor.vertices;
      final normals = anchor.normals;
      final faces = anchor.faces;
      final transform = anchor.transform;

      // Write vertices transformed to world space
      for (int i = 0; i < anchor.vertexCount; i++) {
        final localPos = Vector4(
          vertices[i * 3],
          vertices[i * 3 + 1],
          vertices[i * 3 + 2],
          1.0,
        );
        final worldPos = transform * localPos;
        buffer.writeln(
            'v ${worldPos.x.toStringAsFixed(6)} ${worldPos.y.toStringAsFixed(6)} ${worldPos.z.toStringAsFixed(6)}');
      }

      // Write normals transformed to world space (rotation only)
      final normalMatrix = Matrix4.copy(transform);
      normalMatrix.setColumn(3, Vector4(0, 0, 0, 1));
      for (int i = 0; i < anchor.vertexCount; i++) {
        final localNormal = Vector4(
          normals[i * 3],
          normals[i * 3 + 1],
          normals[i * 3 + 2],
          0.0,
        );
        final worldNormal = normalMatrix * localNormal;
        buffer.writeln(
            'vn ${worldNormal.x.toStringAsFixed(6)} ${worldNormal.y.toStringAsFixed(6)} ${worldNormal.z.toStringAsFixed(6)}');
      }

      // Write faces with 1-based indices and cross-anchor offset
      for (int i = 0; i < anchor.faceCount; i++) {
        final i0 = faces[i * 3] + 1 + vertexOffset;
        final i1 = faces[i * 3 + 1] + 1 + vertexOffset;
        final i2 = faces[i * 3 + 2] + 1 + vertexOffset;
        buffer.writeln('f $i0//$i0 $i1//$i1 $i2//$i2');
      }

      vertexOffset += anchor.vertexCount;
      buffer.writeln();
    }

    return buffer.toString();
  }
}
