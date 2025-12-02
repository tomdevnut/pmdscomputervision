import Flutter
import UIKit

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

    let lidarFactory = LidarViewFactory(messenger: controller.binaryMessenger)
    self.registrar(forPlugin: "devnut-lidar-plugin")!.register(
      lidarFactory,
      withId: "devnut.lidar_view"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
