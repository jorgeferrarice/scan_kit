import Flutter
import ARKit

public class ScanKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.jorgeferrarice.scankit",
            binaryMessenger: registrar.messenger()
        )
        let instance = ScanKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let factory = ScanKitViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "dev.jorgeferrarice.scankit/ar_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isLiDARSupported":
            if #available(iOS 13.4, *) {
                result(LiDARScanner.isSupported)
            } else {
                result(false)
            }
        case "isTrueDepthSupported":
            result(TrueDepthScanner.isSupported)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
