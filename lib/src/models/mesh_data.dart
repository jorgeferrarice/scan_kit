import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';

/// Classification of a mesh surface detected by ARKit.
enum MeshClassification {
  /// No classification.
  none,

  /// A vertical wall surface.
  wall,

  /// A horizontal floor surface.
  floor,

  /// A horizontal ceiling surface.
  ceiling,

  /// A table or desk surface.
  table,

  /// A seat or chair surface.
  seat,

  /// A window surface.
  window,

  /// A door surface.
  door,
}

/// A single mesh anchor captured by the AR scanner.
///
/// Each anchor represents a distinct surface region with its own geometry
/// (vertices, normals, faces) and a [classification] label.
class ScanKitMeshAnchor {
  /// Unique identifier for this anchor.
  final String identifier;

  /// The 4x4 transform matrix positioning this anchor in world space.
  final Matrix4 transform;

  /// Flat array of vertex positions (x, y, z triples).
  final Float32List vertices;

  /// Flat array of vertex normals (x, y, z triples).
  final Float32List normals;

  /// Flat array of face indices (triangle index triples).
  final Uint32List faces;

  /// The surface classification for this anchor.
  final MeshClassification classification;

  const ScanKitMeshAnchor({
    required this.identifier,
    required this.transform,
    required this.vertices,
    required this.normals,
    required this.faces,
    this.classification = MeshClassification.none,
  });

  /// The number of vertices in this anchor.
  int get vertexCount => vertices.length ~/ 3;

  /// The number of triangular faces in this anchor.
  int get faceCount => faces.length ~/ 3;

  factory ScanKitMeshAnchor.fromMap(Map<String, dynamic> map) {
    final transformList = map['transform'];
    final Matrix4 transform;
    if (transformList is Float64List) {
      transform = Matrix4.fromList(transformList.toList());
    } else if (transformList is List) {
      transform = Matrix4.fromList(transformList.cast<double>());
    } else {
      transform = Matrix4.identity();
    }

    return ScanKitMeshAnchor(
      identifier: map['identifier'] as String? ?? '',
      transform: transform,
      vertices: _toFloat32List(map['vertices']),
      normals: _toFloat32List(map['normals']),
      faces: _toUint32List(map['faces']),
      classification: MeshClassification.values[
          (map['classification'] as int?) ?? 0],
    );
  }

  static Float32List _toFloat32List(dynamic value) {
    if (value is Float32List) return value;
    if (value is List) return Float32List.fromList(value.cast<double>());
    return Float32List(0);
  }

  static Uint32List _toUint32List(dynamic value) {
    if (value is Uint32List) return value;
    if (value is List) return Uint32List.fromList(value.cast<int>());
    return Uint32List(0);
  }
}

/// A collection of [ScanKitMeshAnchor]s representing the scanned 3D mesh.
class ScanKitMeshData {
  /// The list of mesh anchors in this data set.
  final List<ScanKitMeshAnchor> anchors;

  const ScanKitMeshData({required this.anchors});

  /// Total number of vertices across all anchors.
  int get totalVertexCount =>
      anchors.fold(0, (sum, a) => sum + a.vertexCount);

  /// Total number of triangular faces across all anchors.
  int get totalFaceCount =>
      anchors.fold(0, (sum, a) => sum + a.faceCount);

  /// Whether this mesh data contains no anchors.
  bool get isEmpty => anchors.isEmpty;

  factory ScanKitMeshData.fromMap(Map<String, dynamic> map) {
    final anchorList = map['anchors'] as List? ?? [];
    return ScanKitMeshData(
      anchors: anchorList
          .cast<Map<String, dynamic>>()
          .map((a) => ScanKitMeshAnchor.fromMap(a))
          .toList(),
    );
  }
}
