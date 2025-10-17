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
    private let processingQueue = DispatchQueue(
        label: "plyview.scene.processing", qos: .userInitiated)
    private let confidenceDiscardThreshold: Float = 0.0  // Drop only points explicitly flagged as invalid

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
        _view.showsStatistics = false
        _view.debugOptions = []
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
        processingQueue.async { [weak self] in
            guard let self else { return }

            let asset = MDLAsset(url: localUrl)
            let meshes = (asset.childObjects(of: MDLMesh.self) as? [MDLMesh]) ?? []

            guard !meshes.isEmpty else {
                DispatchQueue.main.async {
                    completion(
                        FlutterError(
                            code: "ASSET_EMPTY", message: "MDLAsset contains no mesh.",
                            details: nil))
                }
                return
            }

            let rootNode = SCNNode()

            for mesh in meshes {
                guard let geometry = self.buildPointGeometry(from: mesh) else { continue }
                let meshNode = SCNNode(geometry: geometry)
                rootNode.addChildNode(meshNode)
            }

            guard !rootNode.childNodes.isEmpty else {
                DispatchQueue.main.async {
                    completion(
                        FlutterError(
                            code: "NO_POINTS",
                            message: "No valid points found after filtering.", details: nil))
                }
                return
            }

            let (center, radius) = rootNode.boundingSphere

            DispatchQueue.main.async {
                self._view.scene?.rootNode.enumerateChildNodes { child, _ in
                    child.removeFromParentNode()
                }
                self._view.scene?.rootNode.addChildNode(rootNode)

                rootNode.enumerateChildNodes { child, _ in
                    guard let geometry = child.geometry else { return }
                    for element in geometry.elements {
                        element.pointSize = 4.0
                        element.minimumPointScreenSpaceRadius = 1.0
                        element.maximumPointScreenSpaceRadius = 20.0
                    }
                }

                if let cameraNode = self._view.pointOfView {
                    cameraNode.position = SCNVector3(
                        center.x, center.y, center.z + Float(radius) * 2.5)
                    cameraNode.look(at: center)
                }

                completion(nil)
            }
        }
    }

    private func buildPointGeometry(from mesh: MDLMesh) -> SCNGeometry? {
        guard
            let positionAttribute = mesh.vertexAttributeData(
                forAttributeNamed: MDLVertexAttributePosition, as: .float3)
        else { return nil }

        let colorAttribute = mesh.vertexAttributeData(
            forAttributeNamed: MDLVertexAttributeColor, as: .float3)
        let confidenceAttributeName = confidenceAttributeName(in: mesh)
        let confidenceAttribute = confidenceAttributeName.flatMap {
            mesh.vertexAttributeData(forAttributeNamed: $0, as: .float)
        }

        var positions: [SIMD3<Float>] = []
        positions.reserveCapacity(mesh.vertexCount)
        var colors: [SIMD3<Float>] = []
        if colorAttribute != nil { colors.reserveCapacity(mesh.vertexCount) }

        for index in 0..<mesh.vertexCount {
            if let confidenceAttribute {
                let confidence = readFloat(from: confidenceAttribute, index: index)
                if confidence <= confidenceDiscardThreshold { continue }
            }

            let position = readFloat3(from: positionAttribute, index: index)
            if !position.x.isFinite || !position.y.isFinite || !position.z.isFinite {
                continue
            }
            positions.append(position)

            if let colorAttribute {
                let color = readFloat3(from: colorAttribute, index: index)
                colors.append(color)
            }
        }

        guard !positions.isEmpty else { return nil }

        let positionData = positions.withUnsafeBufferPointer { Data(buffer: $0) }
        let positionSource = SCNGeometrySource(
            data: positionData, semantic: .vertex, vectorCount: positions.count,
            usesFloatComponents: true, componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0, dataStride: MemoryLayout<SIMD3<Float>>.size)

        var sources: [SCNGeometrySource] = [positionSource]

        if !colors.isEmpty {
            let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
            let colorSource = SCNGeometrySource(
                data: colorData, semantic: .color, vectorCount: colors.count,
                usesFloatComponents: true, componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0, dataStride: MemoryLayout<SIMD3<Float>>.size)
            sources.append(colorSource)
        }

        var indices = Array(0..<positions.count).map { UInt32($0) }
        let indicesData = indices.withUnsafeBufferPointer { Data(buffer: $0) }
        let element = SCNGeometryElement(
            data: indicesData, primitiveType: .point,
            primitiveCount: positions.count, bytesPerIndex: MemoryLayout<UInt32>.size)

        let geometry = SCNGeometry(sources: sources, elements: [element])
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.white
        material.isDoubleSided = true
        geometry.materials = [material]

        return geometry
    }

    private func readFloat3(from attribute: MDLVertexAttributeData, index: Int) -> SIMD3<Float> {
        let basePointer = attribute.dataStart.advanced(by: index * attribute.stride)
        let floatPointer = basePointer.assumingMemoryBound(to: Float.self)
        return SIMD3(floatPointer[0], floatPointer[1], floatPointer[2])
    }

    private func readFloat(from attribute: MDLVertexAttributeData, index: Int) -> Float {
        let basePointer = attribute.dataStart.advanced(by: index * attribute.stride)
        return basePointer.assumingMemoryBound(to: Float.self).pointee
    }

    private func confidenceAttributeName(in mesh: MDLMesh) -> String? {
        guard let attributes = mesh.vertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return nil
        }

        for attribute in attributes {
            let lowered = attribute.name.lowercased()
            if lowered.contains("confidence") {
                return attribute.name
            }
        }

        return nil
    }
}
