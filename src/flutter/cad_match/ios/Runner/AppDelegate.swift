import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    import ARScannerService
    
    let scannerChannel = FlutterMethodChannel(name: "com.example.flutter_scanning_app/scanner",
                                              binaryMessenger: controller.binaryMessenger)
    
    scannerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      guard let arView = controller.view as? ARSCNView else {
        result(FlutterError(code: "UNAVAILABLE", message: "ARSCNView not found", details: nil))
        return
      }
      
      if call.method == "saveARData" {
        arView.saveSceneToOBJ { url in
          if let savedURL = url {
            result(savedURL.path)
          } else {
            result(nil)
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}