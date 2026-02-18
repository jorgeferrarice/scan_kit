import ARKit
import Flutter

class MeshSerializer {

    @available(iOS 13.4, *)
    static func serialize(meshAnchors: [ARMeshAnchor]) -> [[String: Any]] {
        return meshAnchors.map { anchor in
            let geometry = anchor.geometry
            let vertices = extractVertices(from: geometry)
            let normals = extractNormals(from: geometry)
            let faces = extractFaces(from: geometry)
            var transform = matrixToArray(anchor.transform)
            let classification = extractClassification(from: geometry)

            return [
                "identifier": anchor.identifier.uuidString,
                "transform": FlutterStandardTypedData(float64: Data(bytes: &transform, count: transform.count * 8)),
                "vertices": FlutterStandardTypedData(float32: floatData(vertices)),
                "normals": FlutterStandardTypedData(float32: floatData(normals)),
                "faces": FlutterStandardTypedData(int32: uint32Data(faces)),
                "classification": classification,
            ] as [String : Any]
        }
    }

    static func serializeFaceAnchor(_ anchor: ARFaceAnchor) -> [[String: Any]] {
        let geometry = anchor.geometry
        let vertexCount = geometry.vertices.count
        let triangleCount = geometry.triangleCount

        var vertexFloats = [Float]()
        vertexFloats.reserveCapacity(vertexCount * 3)
        for i in 0..<vertexCount {
            let v = geometry.vertices[i]
            vertexFloats.append(v.x)
            vertexFloats.append(v.y)
            vertexFloats.append(v.z)
        }

        // ARFaceGeometry does not provide normals; fill with zeros
        var normalFloats = [Float](repeating: 0, count: vertexCount * 3)

        var faceIndices = [UInt32]()
        faceIndices.reserveCapacity(triangleCount * 3)
        for i in 0..<triangleCount {
            faceIndices.append(UInt32(geometry.triangleIndices[i * 3]))
            faceIndices.append(UInt32(geometry.triangleIndices[i * 3 + 1]))
            faceIndices.append(UInt32(geometry.triangleIndices[i * 3 + 2]))
        }

        var transform = matrixToArray(anchor.transform)

        return [[
            "identifier": anchor.identifier.uuidString,
            "transform": FlutterStandardTypedData(float64: Data(bytes: &transform, count: transform.count * 8)),
            "vertices": FlutterStandardTypedData(float32: Data(bytes: vertexFloats, count: vertexFloats.count * 4)),
            "normals": FlutterStandardTypedData(float32: Data(bytes: &normalFloats, count: normalFloats.count * 4)),
            "faces": FlutterStandardTypedData(int32: Data(bytes: faceIndices, count: faceIndices.count * 4)),
            "classification": 0,
        ]]
    }

    // MARK: - Private helpers

    @available(iOS 13.4, *)
    private static func extractVertices(from geometry: ARMeshGeometry) -> [Float] {
        let source = geometry.vertices
        let count = source.count
        let stride = source.stride
        let buffer = source.buffer
        var result = [Float]()
        result.reserveCapacity(count * 3)

        let pointer = buffer.contents()
        for i in 0..<count {
            let offset = i * stride
            let x = pointer.load(fromByteOffset: offset, as: Float.self)
            let y = pointer.load(fromByteOffset: offset + 4, as: Float.self)
            let z = pointer.load(fromByteOffset: offset + 8, as: Float.self)
            result.append(x)
            result.append(y)
            result.append(z)
        }
        return result
    }

    @available(iOS 13.4, *)
    private static func extractNormals(from geometry: ARMeshGeometry) -> [Float] {
        let source = geometry.normals
        let count = source.count
        let stride = source.stride
        let buffer = source.buffer
        var result = [Float]()
        result.reserveCapacity(count * 3)

        let pointer = buffer.contents()
        for i in 0..<count {
            let offset = i * stride
            let x = pointer.load(fromByteOffset: offset, as: Float.self)
            let y = pointer.load(fromByteOffset: offset + 4, as: Float.self)
            let z = pointer.load(fromByteOffset: offset + 8, as: Float.self)
            result.append(x)
            result.append(y)
            result.append(z)
        }
        return result
    }

    @available(iOS 13.4, *)
    private static func extractFaces(from geometry: ARMeshGeometry) -> [UInt32] {
        let faces = geometry.faces
        let count = faces.count
        let indexCountPerPrimitive = faces.indexCountPerPrimitive
        let bytesPerIndex = faces.bytesPerIndex
        let buffer = faces.buffer
        var result = [UInt32]()
        result.reserveCapacity(count * indexCountPerPrimitive)

        let pointer = buffer.contents()
        for i in 0..<(count * indexCountPerPrimitive) {
            let offset = i * bytesPerIndex
            if bytesPerIndex == 4 {
                result.append(pointer.load(fromByteOffset: offset, as: UInt32.self))
            } else {
                result.append(UInt32(pointer.load(fromByteOffset: offset, as: UInt16.self)))
            }
        }
        return result
    }

    @available(iOS 13.4, *)
    private static func extractClassification(from geometry: ARMeshGeometry) -> Int {
        guard let classSource = geometry.classification else { return 0 }
        let count = classSource.count
        guard count > 0 else { return 0 }

        // Read the first face classification as the dominant one
        let buffer = classSource.buffer
        let stride = classSource.stride
        let pointer = buffer.contents()
        let value = pointer.load(fromByteOffset: 0, as: UInt8.self)
        return Int(value)
    }

    private static func matrixToArray(_ m: simd_float4x4) -> [Double] {
        return [
            Double(m.columns.0.x), Double(m.columns.0.y), Double(m.columns.0.z), Double(m.columns.0.w),
            Double(m.columns.1.x), Double(m.columns.1.y), Double(m.columns.1.z), Double(m.columns.1.w),
            Double(m.columns.2.x), Double(m.columns.2.y), Double(m.columns.2.z), Double(m.columns.2.w),
            Double(m.columns.3.x), Double(m.columns.3.y), Double(m.columns.3.z), Double(m.columns.3.w),
        ]
    }

    private static func floatData(_ floats: [Float]) -> Data {
        var copy = floats
        return Data(bytes: &copy, count: copy.count * MemoryLayout<Float>.size)
    }

    private static func uint32Data(_ indices: [UInt32]) -> Data {
        var copy = indices
        return Data(bytes: &copy, count: copy.count * MemoryLayout<UInt32>.size)
    }
}
