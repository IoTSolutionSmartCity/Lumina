import SwiftUI
import RealityKit
import Combine

struct LampPreview3D: View {
    var color: Color
    var brightness: Double
    var isOn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxxl)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            RealityKitView(color: color, brightness: brightness, isOn: isOn)
                .clipShape(RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl))
        }
        .frame(height: 300)
    }
}

struct RealityKitView: UIViewRepresentable {
    var color: Color
    var brightness: Double
    var isOn: Bool

    func makeUIView(context: Context) -> RealityKit.RenderingView {
        let view = RealityKit.RenderingView()
        view.renderOptions = [.disableMotionBlur, .disableDepthOfField]

        let scene = buildLampScene()
        view.scene = scene

        context.coordinator.lightEntity = scene.lampLight
        context.coordinator.rootEntity = scene

        return view
    }

    func updateUIView(_ uiView: RealityKit.RenderingView, context: Context) {
        let intensity: Float = isOn ? Float(brightness) * 3000 : 0
        let lightColor = UIColor(color)

        if let light = context.coordinator.lightEntity {
            light.light = PointLightComponent.Light(color: lightColor, intensity: intensity)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func buildLampScene() -> Entity {
        let root = Entity()

        // Base platform
        let baseMesh = MeshResource.generateCylinder(height: 0.04, radius: 0.4)
        let baseMaterial = SimpleMaterial(color: UIColor(Color(hex: "1A1A2E")), isMetallic: false)
        let baseEntity = ModelEntity(mesh: baseMesh, materials: [baseMaterial])
        baseEntity.position = SIMD3<Float>(0, -0.5, 0)
        root.addChild(baseEntity)

        // Lamp body - main pole
        let poleMesh = MeshResource.generateCylinder(height: 0.6, radius: 0.03)
        let poleMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.8), isMetallic: true)
        let poleEntity = ModelEntity(mesh: poleMesh, materials: [poleMaterial])
        poleEntity.position = SIMD3<Float>(0, -0.2, 0)
        root.addChild(poleEntity)

        // Lamp shade - cone
        let shadeMesh = MeshResource.generateCone(height: 0.25, radius: 0.22)
        let shadeMaterial = SimpleMaterial(color: UIColor(Color(hex: "16213E")).withAlphaComponent(0.9), isMetallic: false)
        let shadeEntity = ModelEntity(mesh: shadeMesh, materials: [shadeMaterial])
        shadeEntity.position = SIMD3<Float>(0, 0.2, 0)
        shadeEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        root.addChild(shadeEntity)

        // Light bulb indicator (the glowing part)
        let bulbMesh = MeshResource.generateSphere(radius: 0.08)
        let bulbMaterial = SimpleMaterial(color: UIColor(Color(hex: "7C3AED")), isMetallic: false)
        let bulbEntity = ModelEntity(mesh: bulbMesh, materials: [bulbMaterial])
        bulbEntity.position = SIMD3<Float>(0, 0.12, 0)
        root.addChild(bulbEntity)

        // Point light
        let lampLight = PointLight()
        lampLight.light = PointLightComponent.Light(color: UIColor(Color(hex: "7C3AED")), intensity: 1500)
        lampLight.position = SIMD3<Float>(0, 0.1, 0)
        root.addChild(lampLight)

        // Store reference to light entity for updates
        root.lampLight = lampLight

        // Ambient light
        let ambient = DirectionalLight()
        ambient.light = DirectionalLightComponent.Light(color: .white, intensity: 300)
        ambient.orientation = simd_quatf(angle: -.pi / 4, axis: SIMD3<Float>(1, 0, 0))
        root.addChild(ambient)

        // Camera
        let camera = PerspectiveCamera()
        camera.position = SIMD3<Float>(0, 0.3, 1.8)
        root.addChild(camera)

        return root
    }

    class Coordinator {
        var lightEntity: Entity?
        var rootEntity: Entity?
    }
}

extension Entity {
    static var lampLightKey: UInt8 = 0

    var lampLight: PointLight? {
        get { components[PointLightComponent.self] as? PointLight }
        set {
            if let light = newValue {
                components.set(light)
            }
        }
    }
}

struct LampPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LuminaTheme.CornerRadius.xxl)
                .fill(Color.black.opacity(0.2))

            VStack(spacing: 12) {
                AnimatedGlowIcon(systemName: "lamp.desk.fill", color: LuminaTheme.neonPurple, size: 48, glowRadius: 12)
                Text("Lamp Preview")
                    .font(LuminaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(height: 300)
    }
}
