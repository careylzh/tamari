//
//  AppModel.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import Combine
import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    var attachments: RealityViewAttachments?
    
    enum ErrorState: Equatable {
        case noError
        case providerNotSupported
        case providerNotAuthorized
        case sessionError(ARKitSession.Error)
        
        static func == (lhs: AppModel.ErrorState, rhs: AppModel.ErrorState) -> Bool {
            switch (lhs, rhs) {
            case (.noError, .noError): return true
            case (.providerNotSupported, .providerNotSupported): return true
            case (.providerNotAuthorized, .providerNotAuthorized): return true
            case (.sessionError(let lhsError), .sessionError(let rhsError)): return lhsError.code == rhsError.code
            default: return false
            }
        }
    }
    
    private let session = ARKitSession()
    private let imageTracking = ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "ARImages2"))
    
    let contentRoot = Entity()
    var cube = Entity()
    var Lcube = Entity()
    var Scube = Entity()
    var portalWorld = Entity()
    
    var imageAnchors = [UUID: ImageAnchor]()
    var entityMap = [UUID: Entity]()
    var imageAnchorButton = Entity()
    var showLinearView = false
    
    var imageWidth: Float = 0
    var imageHeight: Float = 0
    
    
    var cancellables: [Cancellable] = []
    
    // When a person denies authorization or a data provider state changes to an error condition,
    // the main window displays an error message based on the `errorState`.
    var errorState: ErrorState = .noError
    
    init() {
        setupPortalWorld()
        if !areAllDataProvidersSupported {
            errorState = .providerNotSupported
        }
        Task {
            if await !areAllDataProvidersAuthorized() {
                errorState = .providerNotAuthorized
            }
        }
    }
    
    private func setupPortalWorld() {
        portalWorld.components.set(WorldComponent())
        
        // Create a simple environment for the portal world
        let material = UnlitMaterial(color: .systemBlue)
        let skybox = Entity()
        skybox.components.set(ModelComponent(mesh: .generateSphere(radius: 10), materials: [material]))
        skybox.scale *= .init(x: -1, y: 1, z: 1) // Flip inside out
//        portalWorld.addChild(skybox)AR R
    }
    
    /// Sets up the root entity in the scene.
    func setupContentEntity() -> Entity {
        contentRoot.addChild(portalWorld)
        return contentRoot
    }
    
    private var areAllDataProvidersSupported: Bool {
        return ImageTrackingProvider.isSupported
    }
    
    func areAllDataProvidersAuthorized() async -> Bool {
        // It's sufficient to check that the authorization status isn't 'denied'.
        // If it's `notdetermined`, ARKit presents a permission pop-up menu that appears as soon
        // as the session runs.
        let authorization = await ARKitSession().queryAuthorization(for: [.worldSensing])
        return authorization[.worldSensing] != .denied
    }
    
    /// Responds to events such as authorization revocation.
    func monitorSessionUpdates() async {
        for await event in session.events {
            logger.info("\(event.description)")
            switch event {
            case .authorizationChanged(type: _, status: let status):
                logger.info("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = .providerNotAuthorized
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                logger.info("Data providers state changed: \(providers), \(state)")
                if let error {
                    logger.error("Data provider reached an error state: \(error)")
                    errorState = .sessionError(error)
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
    
    func runSession() async {
        do {
            try await session.run([imageTracking])
        } catch {
            guard error is ARKitSession.Error else {
                preconditionFailure("Unexpected error \(error).")
            }
            // Session errors are handled in AppModel.monitorSessionUpdates().
        }
    }
    
    func processImageTrackingUpdates() async {
        for await update in imageTracking.anchorUpdates {
            let imageAnchor = update.anchor
            switch update.event {
            case .added:
                await createImage(imageAnchor)
            case .updated:
                updateImage(imageAnchor)
            case .removed:
                removeImage(imageAnchor)
            }
        }
    }
    
    func createImage(_ anchor: ImageAnchor) async {
        print("Creating image")
        if imageAnchors[anchor.id] == nil {
            // Add a new entity to represent this image.
            let scaleFactor = anchor.estimatedScaleFactor
            let imagePhysicalSize = anchor.referenceImage.physicalSize
            let width = Float(imagePhysicalSize.width) * scaleFactor
            imageWidth = width
            let height = Float(imagePhysicalSize.height) * scaleFactor
            imageHeight = height
            let quad = MeshResource.generatePlane(width: width, height: height)
            let transparentColor = UIColor.white.withAlphaComponent(0.0)
            let transparentMaterial = SimpleMaterial(color: transparentColor, isMetallic: false)
            let entity = ModelEntity(mesh: quad, materials: [transparentMaterial])
            entity.name = "imageEntity_\(anchor.id)"
            entity.components.set(PortalComponent(target: portalWorld,
                                                  clippingMode: .plane(.positiveZ),
                                                  crossingMode: .plane(.positiveZ)))
            let cubeMesh = MeshResource.generateBox(size: 0.05)
            let cubeMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            cube = ModelEntity(mesh: cubeMesh, materials: [transparentMaterial])
            Lcube = ModelEntity(mesh: cubeMesh, materials: [transparentMaterial])
            Scube = ModelEntity(mesh: cubeMesh, materials: [transparentMaterial])
            cube.position = SIMD3<Float>(0, 0, 0)
            //Scube.position = SIMD3<Float>(-1.5, 0, 0)
            
            entity.addChild(Lcube)  
            
            // Add to the tracked image entity and position it on top
            
            
            entity.addChild(cube)
            entity.addChild(Scube)
            
            if let glassCubeAttachmentSecond = attachments?.entity(for: "GlassCubeLabelSecond") {
                print("test")
                  //4. Position the Attachment and add it to the RealityViewContent
                
                //glassCubeAttachmentSecond.position = [1.5, 0, 1.45]
                glassCubeAttachmentSecond.transform.rotation = simd_quatf(angle: -.pi/2, axis: [0, 0, 1])
                glassCubeAttachmentSecond.position = [0,0,0]
                Lcube.addChild(glassCubeAttachmentSecond)
                print(cube.children)
            }
              
          if let glassCubeAttachment = attachments?.entity(for: "GlassCubeLabel") {
                        //4. Position the Attachment and add it to the RealityViewContent
                      
              // glassCubeAttachment.position = [0, 0, 0]
                     
              let rotationY = simd_quatf(angle: -.pi/2, axis: [0, 1, 0])

              // 2. Second rotation: pi/2 about the X-axis of the new, rotated frame.
              let rotationX = simd_quatf(angle: .pi/2, axis: [1, 0, 0])

              // 3. Combine the rotations. The order of multiplication is important.
              //    To apply rotationY first, then rotationX, we multiply them as follows.
              //    The second rotation (rotationX) is multiplied by the first (rotationY).
              glassCubeAttachment.transform.rotation = rotationY * rotationX
              glassCubeAttachment.position = [0,-1,1]
                      Lcube.addChild(glassCubeAttachment)
              print(cube.children)
              //Lcube.transform.rotation=simd_quatf(angle: .pi/2, axis: [0, 1, 0])
              //
              let translation = SIMD3<Float>(0, 0, -8.0)
              //
              Lcube.transform.translation += translation

                  }
            
     
            if let glassCubeAttachmentPendulum = attachments?.entity(for: "GlassCubeLabelPendulum") {
                          //4. Position the Attachment and add it to the RealityViewContent
                        
                // glassCubeAttachment.position = [0, 0, 0]
                        glassCubeAttachmentPendulum.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                glassCubeAttachmentPendulum.position = [0, 1, 0]
                
                        cube.addChild(glassCubeAttachmentPendulum)
                cube.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                print(cube.children)
                    }
            if let glassCubeAttachmentSpiral = attachments?.entity(for: "SpiralView") {
                          //4. Position the Attachment and add it to the RealityViewContent
                        
                // glassCubeAttachment.position = [0, 0, 0]
                        glassCubeAttachmentSpiral.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                glassCubeAttachmentSpiral.position = [0, 0.9, -2]
                        Scube.addChild(glassCubeAttachmentSpiral)
                
                    }
            entityMap[anchor.id] = entity
            contentRoot.addChild(entity)
            imageAnchors[anchor.id] = anchor
            
            // Add the button near the image anchor
            if imageAnchorButton.parent == nil {
                entity.addChild(imageAnchorButton)
                // Position the button below and in front of the image
                imageAnchorButton.position = [0, -height/2 - 0.1, 0.05]
            }
        }
        
        if anchor.isTracked {
//            var transform = Transform(matrix: anchor.originFromAnchorTransform)
//            let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Align entity to Poster
//            transform.rotation = transform.rotation * rotationX
//            entityMap[anchor.id]?.transform = transform
        }
    }
    
    func updateImage(_ anchor: ImageAnchor) {
        if anchor.isTracked {
            var transform = Transform(matrix: anchor.originFromAnchorTransform)
            let rotationX = simd_quatf(angle: -.pi/2, axis: [1, 0, 0]) // Align entity to Poster
            //transform.rotation = transform.rotation * rotationX
            let zeroRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
               
               // Set the entity's orientation
               transform.rotation = zeroRotation
            entityMap[anchor.id]?.transform = transform
            imageAnchors[anchor.id] = anchor
        }
    }
    
    func removeImage(_ anchor: ImageAnchor) {
        entityMap[anchor.id]?.removeFromParent()
        entityMap[anchor.id] = nil
        imageAnchors[anchor.id] = nil
    }
}
