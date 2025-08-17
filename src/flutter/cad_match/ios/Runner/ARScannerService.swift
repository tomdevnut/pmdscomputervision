import Foundation
import Flutter
import ARKit
import ModelIO
import UniformTypeIdentifiers
import RealityKit

// Estensione per ARSCNView per salvare la mesh in un file .obj
extension ARSCNView {
    func saveSceneToOBJ(completion: @escaping (URL?) -> Void) {
        let modelsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Scans")
        let fileName = UUID().uuidString + ".obj"
        let fileURL = modelsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let scene = SCNScene()
            var allNodes: [SCNNode] = []
            
            // Trova tutti i nodi di tipo SCNGeometry che rappresentano la mesh della scansione
            // Nota: RealityKit è più adatto per il salvataggio di mesh, ma SCNNode funziona per compatibilità
            enumerateHierarchy({ (node, _) in
                if node.geometry is SCNGeometry {
                    allNodes.append(node)
                }
            })
            
            let asset = MDLAsset()
            
            for node in allNodes {
                if let geometry = node.geometry {
                    let mesh = MDLMesh(scnGeometry: geometry)
                    asset.add(mesh)
                }
            }
            
            // Imposta l'estensione di file per l'esportazione -> modificare se scegliamo .ply
            let options = [MDLAsset.urlAssetExportFileTypeKey: UTType.obj]
            try asset.export(to: fileURL, options: options)
            
            print("Successfully saved OBJ file to: \(fileURL.path)")
            completion(fileURL)
            
        } catch {
            print("Failed to save OBJ file: \(error.localizedDescription)")
            completion(nil)
        }
    }
}