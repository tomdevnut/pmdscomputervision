import Flutter
import ModelIO
import SceneKit
import SceneKit.ModelIO
import UIKit

class PlyViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
        -> FlutterPlatformView
    {
        return PlyView(
            frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PlyView: NSObject, FlutterPlatformView {
    private var _view: SCNView
    private var methodChannel: FlutterMethodChannel

    init(
        frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = SCNView(frame: frame)
        methodChannel = FlutterMethodChannel(
            name: "ply_viewer_\(viewId)", binaryMessenger: messenger)
        super.init()
        createScene()

        methodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "loadModel" {
                // Ora ci aspettiamo una mappa con URL e scanId
                guard let args = call.arguments as? [String: Any],
                    let urlString = args["url"] as? String,
                    let scanId = args["scanId"] as? String,
                    let url = URL(string: urlString)
                else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGS", message: "URL/scanId are invalid", details: nil))
                    return
                }
                self?.loadModel(from: url, scanId: scanId, completion: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
    }

    func view() -> UIView { return _view }

    private func createScene() {
        let scene = SCNScene()
        _view.scene = scene
        _view.allowsCameraControl = true
        _view.backgroundColor = UIColor.white
        _view.autoenablesDefaultLighting = true
    }

    private func loadModel(from remoteUrl: URL, scanId: String, completion: @escaping FlutterResult)
    {
        let fileManager: FileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let localUrl = cacheDirectory.appendingPathComponent("\(scanId).ply")

        // 1. Controlla se il file esiste già in cache
        if fileManager.fileExists(atPath: localUrl.path) {
            print("Loading model from cache: \(localUrl.path)")
            self.loadScene(from: localUrl, completion: completion)
            return
        }

        // 2. Se non esiste, scaricalo
        print("Downloading model to cache: \(localUrl.path)")
        let task = URLSession.shared.dataTask(with: remoteUrl) { data, response, error in
            guard let data = data, error == nil else {
                let errorMessage =
                    "Failed to download model data: \(error?.localizedDescription ?? "Unknown error")"
                completion(
                    FlutterError(code: "DOWNLOAD_FAILED", message: errorMessage, details: nil))
                return
            }

            // 3. Salva il file scaricato nella cache
            do {
                try data.write(to: localUrl)
                // 4. Ora carica la scena dal file locale appena salvato
                self.loadScene(from: localUrl, completion: completion)
            } catch {
                let errorMessage = "Failed to write cache file: \(error)"
                completion(
                    FlutterError(code: "CACHE_WRITE_FAILED", message: errorMessage, details: nil))
            }
        }
        task.resume()
    }

    // Funzione helper per caricare la scena da un URL locale
    private func loadScene(from localUrl: URL, completion: @escaping FlutterResult) {
        do {
            let asset = MDLAsset(url: localUrl)
            guard asset.count > 0 else {
                completion(
                    FlutterError(code: "ASSET_EMPTY", message: "MDLAsset is empty.", details: nil))
                return
            }

            let mdlObject = asset.object(at: 0)
            let node = SCNNode(mdlObject: mdlObject)

            let (center, radius) = node.boundingSphere
            if let cameraNode = self._view.pointOfView {
                cameraNode.position = SCNVector3(center.x, center.y, center.z + Float(radius) * 2.5)
                cameraNode.look(at: center)
            }

            DispatchQueue.main.async {
                self._view.scene?.rootNode.addChildNode(node)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(nil)
                }
            }
        } catch {
            let errorMessage = "Failed to load model from local URL: \(error)"
            completion(FlutterError(code: "LOAD_FAILED", message: errorMessage, details: nil))
        }
    }
}
