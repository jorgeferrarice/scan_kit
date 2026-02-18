import 'dart:convert';
import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import '../models/mesh_data.dart';

class GlbExporter {
  static Uint8List export(ScanKitMeshData meshData) {
    // Merge all anchors into world-space buffers
    int totalVertices = meshData.totalVertexCount;
    int totalFaces = meshData.totalFaceCount;

    final positions = Float32List(totalVertices * 3);
    final normals = Float32List(totalVertices * 3);
    final indices = Uint32List(totalFaces * 3);

    int vertexOffset = 0;
    int indexOffset = 0;

    for (final anchor in meshData.anchors) {
      final transform = anchor.transform;
      final normalMatrix = Matrix4.copy(transform);
      normalMatrix.setColumn(3, Vector4(0, 0, 0, 1));

      for (int i = 0; i < anchor.vertexCount; i++) {
        final localPos = Vector4(
          anchor.vertices[i * 3],
          anchor.vertices[i * 3 + 1],
          anchor.vertices[i * 3 + 2],
          1.0,
        );
        final worldPos = transform * localPos;
        final idx = (vertexOffset + i) * 3;
        positions[idx] = worldPos.x.toDouble() as double;
        positions[idx + 1] = worldPos.y.toDouble() as double;
        positions[idx + 2] = worldPos.z.toDouble() as double;

        final localNormal = Vector4(
          anchor.normals[i * 3],
          anchor.normals[i * 3 + 1],
          anchor.normals[i * 3 + 2],
          0.0,
        );
        final worldNormal = normalMatrix * localNormal;
        normals[idx] = worldNormal.x.toDouble() as double;
        normals[idx + 1] = worldNormal.y.toDouble() as double;
        normals[idx + 2] = worldNormal.z.toDouble() as double;
      }

      for (int i = 0; i < anchor.faceCount * 3; i++) {
        indices[indexOffset + i] = anchor.faces[i] + vertexOffset;
      }

      vertexOffset += anchor.vertexCount;
      indexOffset += anchor.faceCount * 3;
    }

    // Build binary buffer: indices + positions + normals
    final indicesBytes = indices.buffer.asUint8List();
    final positionsBytes = positions.buffer.asUint8List();
    final normalsBytes = normals.buffer.asUint8List();

    final indicesByteLength = indicesBytes.length;
    final positionsByteLength = positionsBytes.length;
    final normalsByteLength = normalsBytes.length;
    final totalBinLength =
        indicesByteLength + positionsByteLength + normalsByteLength;

    // Compute min/max for positions (required by glTF spec)
    double minX = double.infinity,
        minY = double.infinity,
        minZ = double.infinity;
    double maxX = double.negativeInfinity,
        maxY = double.negativeInfinity,
        maxZ = double.negativeInfinity;
    for (int i = 0; i < totalVertices; i++) {
      final x = positions[i * 3];
      final y = positions[i * 3 + 1];
      final z = positions[i * 3 + 2];
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }

    if (totalVertices == 0) {
      minX = minY = minZ = 0;
      maxX = maxY = maxZ = 0;
    }

    // Build glTF JSON
    final gltf = {
      "asset": {"version": "2.0", "generator": "ScanKit"},
      "scene": 0,
      "scenes": [
        {
          "nodes": [0]
        }
      ],
      "nodes": [
        {"mesh": 0}
      ],
      "meshes": [
        {
          "primitives": [
            {
              "attributes": {"POSITION": 1, "NORMAL": 2},
              "indices": 0,
              "mode": 4,
            }
          ]
        }
      ],
      "accessors": [
        {
          "bufferView": 0,
          "componentType": 5125, // UNSIGNED_INT
          "count": totalFaces * 3,
          "type": "SCALAR",
        },
        {
          "bufferView": 1,
          "componentType": 5126, // FLOAT
          "count": totalVertices,
          "type": "VEC3",
          "min": [minX, minY, minZ],
          "max": [maxX, maxY, maxZ],
        },
        {
          "bufferView": 2,
          "componentType": 5126, // FLOAT
          "count": totalVertices,
          "type": "VEC3",
        },
      ],
      "bufferViews": [
        {
          "buffer": 0,
          "byteOffset": 0,
          "byteLength": indicesByteLength,
          "target": 34963, // ELEMENT_ARRAY_BUFFER
        },
        {
          "buffer": 0,
          "byteOffset": indicesByteLength,
          "byteLength": positionsByteLength,
          "target": 34962, // ARRAY_BUFFER
        },
        {
          "buffer": 0,
          "byteOffset": indicesByteLength + positionsByteLength,
          "byteLength": normalsByteLength,
          "target": 34962, // ARRAY_BUFFER
        },
      ],
      "buffers": [
        {"byteLength": totalBinLength}
      ],
    };

    final jsonString = jsonEncode(gltf);
    final jsonBytes = utf8.encode(jsonString);

    // Pad JSON to 4-byte alignment
    final jsonPadding = (4 - (jsonBytes.length % 4)) % 4;
    final paddedJsonLength = jsonBytes.length + jsonPadding;

    // Pad BIN to 4-byte alignment
    final binPadding = (4 - (totalBinLength % 4)) % 4;
    final paddedBinLength = totalBinLength + binPadding;

    // GLB structure: 12-byte header + JSON chunk + BIN chunk
    final totalLength = 12 + 8 + paddedJsonLength + 8 + paddedBinLength;

    final output = ByteData(totalLength);
    int offset = 0;

    // GLB Header
    output.setUint32(offset, 0x46546C67, Endian.little); // magic: glTF
    offset += 4;
    output.setUint32(offset, 2, Endian.little); // version
    offset += 4;
    output.setUint32(offset, totalLength, Endian.little); // total length
    offset += 4;

    // JSON Chunk
    output.setUint32(offset, paddedJsonLength, Endian.little); // chunk length
    offset += 4;
    output.setUint32(offset, 0x4E4F534A, Endian.little); // chunk type: JSON
    offset += 4;
    final outputBytes = output.buffer.asUint8List();
    outputBytes.setRange(offset, offset + jsonBytes.length, jsonBytes);
    offset += jsonBytes.length;
    for (int i = 0; i < jsonPadding; i++) {
      outputBytes[offset++] = 0x20; // space padding for JSON
    }

    // BIN Chunk
    output.setUint32(offset, paddedBinLength, Endian.little); // chunk length
    offset += 4;
    output.setUint32(offset, 0x004E4942, Endian.little); // chunk type: BIN
    offset += 4;
    outputBytes.setRange(offset, offset + indicesByteLength, indicesBytes);
    offset += indicesByteLength;
    outputBytes.setRange(offset, offset + positionsByteLength, positionsBytes);
    offset += positionsByteLength;
    outputBytes.setRange(offset, offset + normalsByteLength, normalsBytes);
    offset += normalsByteLength;
    for (int i = 0; i < binPadding; i++) {
      outputBytes[offset++] = 0x00;
    }

    return outputBytes;
  }
}
