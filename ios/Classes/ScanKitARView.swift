import Flutter
import ARKit

class ScanKitARView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let arView: ARSCNView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var scanner: ScannerProtocol?
    private var streamTimer: Timer?

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        arView = ARSCNView(frame: frame)
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true

        methodChannel = FlutterMethodChannel(
            name: "dev.jorgeferrarice.scankit/view_\(viewId)",
            binaryMessenger: messenger
        )
        eventChannel = FlutterEventChannel(
            name: "dev.jorgeferrarice.scankit/mesh_stream_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        methodChannel.setMethodCallHandler(handle)
        eventChannel.setStreamHandler(self)
    }

    func view() -> UIView {
        return arView
    }

    // MARK: - MethodChannel Handler

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments required", details: nil))
                return
            }
            startScanning(args: args, result: result)
        case "stopScanning":
            stopScanning(result: result)
        case "getSnapshot":
            getSnapshot(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startScanning(args: [String: Any], result: FlutterResult) {
        let mode = args["mode"] as? String ?? "lidar"
        let enableClassification = args["enableClassification"] as? Bool ?? true
        let enableStreaming = args["enableStreaming"] as? Bool ?? true
        let updateFrequencyHz = args["updateFrequencyHz"] as? Int ?? 5

        stopStreamTimer()
        scanner?.stop()

        if mode == "trueDepth" {
            scanner = TrueDepthScanner()
        } else {
            if #available(iOS 13.4, *) {
                let lidar = LiDARScanner()
                lidar.configure(enableClassification: enableClassification)
                scanner = lidar
            } else {
                result(FlutterError(code: "UNSUPPORTED", message: "LiDAR requires iOS 13.4+", details: nil))
                return
            }
        }

        arView.session = scanner!.session
        if scanner is LiDARScanner {
            arView.scene.background.contents = UIColor.clear
        }
        scanner!.start()

        if enableStreaming {
            let interval = 1.0 / Double(max(1, min(30, updateFrequencyHz)))
            streamTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.sendMeshUpdate()
            }
        }

        result(nil)
    }

    private func stopScanning(result: FlutterResult) {
        stopStreamTimer()
        scanner?.stop()
        result(nil)
    }

    private func getSnapshot(result: FlutterResult) {
        let meshData = scanner?.getCurrentMesh() ?? []
        result(["anchors": meshData])
    }

    private func dispose(result: FlutterResult) {
        stopStreamTimer()
        scanner?.stop()
        scanner = nil
        methodChannel.setMethodCallHandler(nil)
        eventChannel.setStreamHandler(nil)
        result(nil)
    }

    // MARK: - Streaming

    private func sendMeshUpdate() {
        guard let sink = eventSink, let scanner = scanner else { return }
        let meshData = scanner.getCurrentMesh()
        sink(["anchors": meshData])
    }

    private func stopStreamTimer() {
        streamTimer?.invalidate()
        streamTimer = nil
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    deinit {
        stopStreamTimer()
        scanner?.stop()
    }
}
