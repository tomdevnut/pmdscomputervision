import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    let plyViewFactory = PlyViewFactory(messenger: controller.binaryMessenger)
    self.registrar(forPlugin: "ply-view-plugin")!.register(
        plyViewFactory,
        withId: "ply_viewer"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
