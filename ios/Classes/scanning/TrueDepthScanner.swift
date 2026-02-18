import ARKit

class TrueDepthScanner: NSObject, ScannerProtocol, ARSessionDelegate {
    let session = ARSession()
    private var latestFaceAnchor: ARFaceAnchor?

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        config.maximumNumberOfTrackedFaces = 1
        session.run(config)
    }

    func stop() {
        session.pause()
    }

    func getCurrentMesh() -> [[String: Any]] {
        guard let anchor = latestFaceAnchor else { return [] }
        return MeshSerializer.serializeFaceAnchor(anchor)
    }

    static var isSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let faceAnchor = anchor as? ARFaceAnchor {
                latestFaceAnchor = faceAnchor
            }
        }
    }
}
