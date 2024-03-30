//
//  BranchLabelVIew.swift
//  hackprinceton
//
//  Created by Anthony Li on 3/30/24.
//

import SwiftUI
import RealityKit

struct BranchLabelView: View {
    var label: String
    var color: UIColor
    
    var resolvedColor: Color {
        Color(color).opacity(0.9)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.body.monospaced())
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding()
                .background(resolvedColor)
                .clipShape(.rect(cornerRadius: 16))
                .lineLimit(1)
                .frame(maxWidth: 300)
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 32, y: 0))
                path.addLine(to: CGPoint(x: 16, y: 16))
                path.closeSubpath()
            }
            .fill(resolvedColor)
            .frame(width: 32, height: 16)
        }
        .padding(1)
    }
}

@MainActor class BranchLabelRenderer {
    private var cache = [String: (UIColor, Entity)]()
    
    func renderBranchLabel(for name: String, color: UIColor) -> Entity? {
        if let (cachedColor, cachedImage) = cache[name], cachedColor == color {
            return cachedImage
        }
        
        let view = BranchLabelView(label: name, color: color)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else {
            return nil
        }
        
        let scaleFactor: Float = 0.18 / Float(300 * renderer.scale)
        let plane = MeshResource.generatePlane(width: scaleFactor * Float(image.width), height: scaleFactor * Float(image.height))
        guard let texture = try? TextureResource.generate(from: image, options: .init(semantic: .color)) else {
            return nil
        }
        
        var material = UnlitMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.999), texture: .init(texture))
        
        let entity = ModelEntity(mesh: plane, materials: [material])
        cache[name] = (color, entity)
        return entity
    }
    
    static let shared = BranchLabelRenderer()
}

#Preview {
    BranchLabelView(label: "reallylongbranchnameaaaaaaaaa", color: .systemPurple)
}
