import ARKit
import Flutter
import Foundation
import SceneKit

class LidarPlatformView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let sceneView: ARSCNView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var lastPointsSent = CFAbsoluteTimeGetCurrent()

    // Stato per controllare l'invio dei punti, non la sessione AR
    private var isRecording = false

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        self.sceneView = ARSCNView(frame: frame)
        self.methodChannel = FlutterMethodChannel(
            name: "devnut.lidar/methods_\(viewId)", binaryMessenger: messenger)
        self.eventChannel = FlutterEventChannel(
            name: "devnut.lidar/points_\(viewId)", binaryMessenger: messenger)
        super.init()
        self.eventChannel.setStreamHandler(self)
        self.methodChannel.setMethodCallHandler(self.handle)
        self.sceneView.delegate = self
        self.sceneView.session.delegate = self
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // Avvia la sessione immediatamente per mostrare il feed della camera
        configureAndRunSession()
    }

    func view() -> UIView { sceneView }

    // MARK: - Stream handler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - Methods
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            // Inizia solo la registrazione dei punti
            isRecording = true
            result(nil)
        case "stop":
            // Ferma solo la registrazione dei punti, la sessione video continua
            isRecording = false
            result(nil)
        case "reset":
            reset()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func configureAndRunSession() {
        #if targetEnvironment(simulator)
            print("LiDAR non disponibile sul simulatore.")
            return
        #endif
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
            if #available(iOS 14.0, *),
                ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
            {
                config.frameSemantics.insert(.smoothedSceneDepth)
            }
        }

        // Avvia la sessione senza metterla in pausa
        sceneView.session.run(config)
    }

    private func reset() {
        // Ferma la registrazione e pulisce la scena
        isRecording = false
        sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        if let config = sceneView.session.configuration {
            // Riavvia la sessione per resettare il tracking
            sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    // Throttle ~10 Hz
    private func shouldSendNow() -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastPointsSent > 0.1 {
            lastPointsSent = now
            return true
        }
        return false
    }

    private func sendPointCloud(from frame: ARFrame) {
        // Invia i punti solo se la registrazione è attiva
        guard let sink = eventSink, isRecording, shouldSendNow() else { return }

        let depth: ARDepthData?
        if #available(iOS 14.0, *) {
            depth = frame.smoothedSceneDepth ?? frame.sceneDepth
        } else {
            depth = frame.sceneDepth
        }
        guard let depthData = depth else { return }

        let depthMap = depthData.depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return }
        let ptr = base.bindMemory(to: Float32.self, capacity: width * height)

        let intr = frame.camera.intrinsics
        let fx = intr.columns.0.x
        let fy = intr.columns.1.y
        let cx = intr.columns.2.x
        let cy = intr.columns.2.y
        let camT = frame.camera.transform

        var out = [Float32]()
        out.reserveCapacity((width * height * 3) / 16)

        // Downsample per prestazioni: campiona ogni "step" pixel
        let step = max(2, min(12, width / 80))
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let d = ptr[y * width + x]
                if !d.isFinite || d <= 0.0 || d > 8.0 { continue }  // fino a ~8m su LiDAR
                let X = (Float32(x) - Float32(cx)) * d / Float32(fx)
                let Y = (Float32(y) - Float32(cy)) * d / Float32(fy)
                let local = simd_float4(X, Y, -d, 1.0)  // camera space (ARKit avanti = -Z)
                let world = camT * local  // world space
                out.append(world.x)
                out.append(world.y)
                out.append(world.z)
            }
        }

        if out.isEmpty { return }
        let data = Data(bytes: out, count: out.count * MemoryLayout<Float32>.size)
        sink(FlutterStandardTypedData(float32: data))
    }
}

extension LidarPlatformView: ARSCNViewDelegate, ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Questo metodo viene sempre chiamato, ma l'invio dei punti è controllato da `isRecording`
        sendPointCloud(from: frame)
    }
}
