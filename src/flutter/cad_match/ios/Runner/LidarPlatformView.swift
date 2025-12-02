import ARKit
import Flutter
import Foundation
import Metal
import SceneKit
import UIKit

class LidarPlatformView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private let sceneView: ARSCNView
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var lastPointsSent = CFAbsoluteTimeGetCurrent()
    private var useSceneMesh = false

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
            useSceneMesh = true
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            useSceneMesh = true
        } else {
            useSceneMesh = false
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

    private func sendMeshPoints(from meshAnchor: ARMeshAnchor) {
        guard let sink = eventSink, isRecording, shouldSendNow() else {
            return
        }

        guard let frame = sceneView.session.currentFrame else { return }

        let geometry = meshAnchor.geometry
        let vertexCount = geometry.vertices.count
        guard vertexCount > 0 else { return }

        let vertexBuffer = geometry.vertices.buffer
        let vertexStride = geometry.vertices.stride
        let vertexOffset = geometry.vertices.offset
        let transform = meshAnchor.transform

        let pixelBuffer = frame.capturedImage
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard
            let yBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
            let cbcrBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        else { return }

        let buffers = ColorBuffers(
            yPtr: yBase.assumingMemoryBound(to: UInt8.self),
            cbcrPtr: cbcrBase.assumingMemoryBound(to: UInt8.self),
            yWidth: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
            yHeight: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
            yBytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0),
            cbcrBytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1),
            cbcrWidth: CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
            cbcrHeight: CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        )

        var out = [Float32]()
        out.reserveCapacity(vertexCount * 6)

        let baseAddress = vertexBuffer.contents().advanced(by: vertexOffset)
        for index in 0..<vertexCount {
            let pointer = baseAddress.advanced(by: index * vertexStride)
            let vertex = pointer.assumingMemoryBound(to: simd_float3.self).pointee
            let worldPosition = transform * simd_float4(vertex, 1.0)
            let colorPixel = projectToColorPixel(
                position: worldPosition,
                frame: frame,
                buffers: buffers
            )
            let color =
                colorPixel.flatMap {
                    sampleColor(pixelX: $0.0, pixelY: $0.1, buffers: buffers)
                } ?? simd_float3(repeating: 0.6)

            out.append(worldPosition.x)
            out.append(worldPosition.y)
            out.append(worldPosition.z)
            out.append(color.x)
            out.append(color.y)
            out.append(color.z)
        }

        if out.isEmpty {
            return
        }
        let data = Data(bytes: out, count: out.count * MemoryLayout<Float32>.size)
        sink(FlutterStandardTypedData(float32: data))
    }

    private func sendPointCloud(from frame: ARFrame) {
        // Invia i punti solo se la registrazione è attiva
        guard !useSceneMesh, let sink = eventSink, isRecording, shouldSendNow() else {
            return
        }

        let depth: ARDepthData?
        if #available(iOS 14.0, *) {
            depth = frame.smoothedSceneDepth ?? frame.sceneDepth
        } else {
            depth = frame.sceneDepth
        }
        guard let depthData = depth else {
            return
        }

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

        let pixelBuffer = frame.capturedImage
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard
            let yBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
            let cbcrBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        else { return }

        let buffers = ColorBuffers(
            yPtr: yBase.assumingMemoryBound(to: UInt8.self),
            cbcrPtr: cbcrBase.assumingMemoryBound(to: UInt8.self),
            yWidth: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
            yHeight: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
            yBytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0),
            cbcrBytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1),
            cbcrWidth: CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
            cbcrHeight: CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        )

        var out = [Float32]()
        out.reserveCapacity(width * height * 6)

        // Processa ogni pixel per ottenere la massima precisione
        for y in 0..<height {
            for x in 0..<width {
                let d = ptr[y * width + x]
                if !d.isFinite || d <= 0.0 || d > 3.0 { continue }  // fino a ~3m su LiDAR
                let X = (Float32(x) - Float32(cx)) * d / Float32(fx)
                let Y = (Float32(y) - Float32(cy)) * d / Float32(fy)
                let local = simd_float4(X, Y, -d, 1.0)  // camera space (ARKit avanti = -Z)
                let world = camT * local  // world space

                let colorPixel = projectToColorPixel(
                    position: world,
                    frame: frame,
                    buffers: buffers
                )
                let color =
                    colorPixel.flatMap {
                        sampleColor(pixelX: $0.0, pixelY: $0.1, buffers: buffers)
                    } ?? simd_float3(repeating: 0.6)

                out.append(world.x)
                out.append(world.y)
                out.append(world.z)
                out.append(color.x)
                out.append(color.y)
                out.append(color.z)
            }
        }

        if out.isEmpty {
            return
        }
        let data = Data(bytes: out, count: out.count * MemoryLayout<Float32>.size)
        sink(FlutterStandardTypedData(float32: data))
    }

    private struct ColorBuffers {
        let yPtr: UnsafePointer<UInt8>
        let cbcrPtr: UnsafePointer<UInt8>
        let yWidth: Int
        let yHeight: Int
        let yBytesPerRow: Int
        let cbcrBytesPerRow: Int
        let cbcrWidth: Int
        let cbcrHeight: Int
    }

    private func projectToColorPixel(
        position: simd_float4,
        frame: ARFrame,
        buffers: ColorBuffers
    ) -> (Int, Int)? {
        // Il buffer della camera è sempre in orientazione landscapeRight
        let orientation: UIInterfaceOrientation = .landscapeRight
        let viewportSize = CGSize(
            width: CGFloat(buffers.yWidth),
            height: CGFloat(buffers.yHeight)
        )
        let projected = frame.camera.projectPoint(
            simd_float3(position.x, position.y, position.z),
            orientation: orientation,
            viewportSize: viewportSize
        )

        guard projected.x.isFinite, projected.y.isFinite else { return nil }

        let px = Int(projected.x.rounded())
        let py = Int(projected.y.rounded())

        if buffers.yWidth == 0 || buffers.yHeight == 0 { return nil }

        let clampedX = min(max(px, 0), buffers.yWidth - 1)
        let clampedY = min(max(py, 0), buffers.yHeight - 1)
        return (clampedX, clampedY)
    }

    private func sampleColor(
        pixelX: Int,
        pixelY: Int,
        buffers: ColorBuffers
    ) -> simd_float3? {
        guard
            pixelX >= 0, pixelX < buffers.yWidth,
            pixelY >= 0, pixelY < buffers.yHeight
        else { return nil }

        let yIndex = pixelY * buffers.yBytesPerRow + pixelX
        let yValue = Float(buffers.yPtr[yIndex])

        let cbRow = pixelY / 2
        let cbCol = pixelX / 2
        guard
            cbRow >= 0, cbRow < buffers.cbcrHeight,
            cbCol >= 0, cbCol < buffers.cbcrWidth
        else { return nil }

        let cbIndex = cbRow * buffers.cbcrBytesPerRow + cbCol * 2
        let cb = Float(buffers.cbcrPtr[cbIndex]) - 128.0
        let cr = Float(buffers.cbcrPtr[cbIndex + 1]) - 128.0

        var r = yValue + 1.402 * cr
        var g = yValue - 0.344136 * cb - 0.714136 * cr
        var b = yValue + 1.772 * cb

        r = max(0.0, min(255.0, r))
        g = max(0.0, min(255.0, g))
        b = max(0.0, min(255.0, b))

        return simd_float3(Float(r / 255.0), Float(g / 255.0), Float(b / 255.0))
    }
}

extension LidarPlatformView: ARSCNViewDelegate, ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard useSceneMesh else { return }
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                sendMeshPoints(from: meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard useSceneMesh else { return }
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                sendMeshPoints(from: meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Questo metodo viene sempre chiamato, ma l'invio dei punti è controllato da `isRecording`
        sendPointCloud(from: frame)
    }
}
