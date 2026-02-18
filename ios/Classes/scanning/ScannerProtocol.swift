import ARKit

protocol ScannerProtocol: AnyObject {
    var session: ARSession { get }
    func start()
    func stop()
    func getCurrentMesh() -> [[String: Any]]
}
