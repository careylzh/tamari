import SwiftUI
import RealityKit
import simd
import AVFoundation

struct LinearWindowView: View {
    @StateObject private var sharedState = SharedState()
    let lengthMeter = 3.0

    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        var firstState = SharedStateSmile()

        RealityView { content, attachments in
            let anchor = AnchorEntity(world: [0,1.5,-2])
            sharedState.triggerID = 0

            content.add(anchor)

            let cubeMesh = MeshResource.generateBox(size: 0.05)
            let cubeMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let cube = ModelEntity(mesh: cubeMesh, materials: [cubeMaterial])
            
            cube.position = SIMD3<Float>(0, 0, 0)
            anchor.addChild(cube)
            
            if let glassCubeAttachment = attachments.entity(for: "GlassCubeLabel") {
                glassCubeAttachment.position = [0, 0, 0]
                glassCubeAttachment.transform.rotation = simd_quatf(angle: .pi, axis: [0, 0, 1])
                anchor.addChild(glassCubeAttachment)
            }
            if let glassCubeAttachmentSecond = attachments.entity(for: "GlassCubeLabelSecond") {
                let halfMeter = lengthMeter / 2
                glassCubeAttachmentSecond.position = SIMD3<Float>(Float(halfMeter), 0, Float(halfMeter))
                glassCubeAttachmentSecond.transform.rotation = simd_quatf(angle: .pi/2, axis: [1, 1, 0])
                
                anchor.addChild(glassCubeAttachmentSecond)
            }
            
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "GlassCubeLabel") {
                LinearView_HK(sharedState: sharedState, invisibleButtons: [3], startButtonID: 3, endButtonID: 6)
                    .frame(width: 1360 * lengthMeter, height: 438 * lengthMeter)
            }
            Attachment(id: "GlassCubeLabelSecond") {
                LinearView_HK(sharedState: sharedState, invisibleButtons: [], startButtonID: 0, endButtonID: 3)
                    .frame(width: 1360 * lengthMeter, height: 438 * lengthMeter)
            }
        }
       // .preferredSurroundingsEffect(.systemDark)
        
    }

    
}

struct LinearWindowViewSecond: View {
    let anchorPosition: SIMD3<Float>
    let rotationAngle: Float

    var body: some View {
        RealityView { content, attachments in
            if let glassCube = try? await Entity(named: "GlassCube") {

                    content.add(glassCube)

                    //3. Retrieve the attachment with the "GlassCubeLabel" identifier as an entity.
                    if let glassCubeAttachment = attachments.entity(for: "GlassCubeLabel") {
                          //4. Position the Attachment and add it to the RealityViewContent
                        glassCubeAttachment.position = [0, 0, 0]
                        glassCube.addChild(glassCubeAttachment)
                    }

                }

            // Render SwiftUI view into RealityView overlay
        } attachments: {
            Attachment(id: "GlassCubeLabel") {
                    //2. Define the SwiftUI View
                    Text("Glass Cube")
                        .font(.extraLargeTitle)
                        .padding()
                        .glassBackgroundEffect()
                }
            
        }
    }
}

//#Preview(windowStyle: .volumetric) {
//    LinearWindowView(anchorPosition: [1, 0, 0], rotationAngle: -.pi / 2)
//}
