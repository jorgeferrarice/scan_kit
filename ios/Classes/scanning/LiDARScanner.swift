import ARKit

@available(iOS 13.4, *)
class LiDARScanner: NSObject, ScannerProtocol, ARSessionDelegate {
    let session = ARSession()
    private var enableClassification: Bool = true

    override init() {
        super.init()
        session.delegate = self
    }

    func configure(enableClassification: Bool) {
        self.enableClassification = enableClassification
    }

    func start() {
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) && enableClassification {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        config.environmentTexturing = .automatic
        session.run(config)
    }

    func stop() {
        session.pause()
    }

    func getCurrentMesh() -> [[String: Any]] {
        let anchors = session.currentFrame?.anchors.compactMap { $0 as? ARMeshAnchor } ?? []
        return MeshSerializer.serialize(meshAnchors: anchors)
    }

    static var isSupported: Bool {
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}
