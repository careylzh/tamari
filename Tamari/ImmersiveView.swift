//
//  ImmersiveView.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @State var tracked = false
    @Environment(AppModel.self) var appModel
    @StateObject private var sharedState = SharedState()
    @StateObject private var sharedStatePendulum = SharedStatePendulum()
    @StateObject private var sharedStateSpiral = SharedStateSpiral()

    let lengthMeter = 2.0
    
    var body: some View {
        
        RealityView { content, attachments in
            content.add(appModel.setupContentEntity())
            sharedState.triggerID = 0
            
            appModel.attachments = attachments
            
                let rotationAngle = Float.pi / 2 // 90 degrees in radians
                let zAxis = SIMD3<Float>(0, 0, 1) // Z-axis
            
        }
         attachments: {
            Attachment(id: "ImageAnchorButton") {
                Button("Start") {
                    appModel.showLinearView = true
                }
                //.glassBackgroundEffect()
            }
             Attachment(id: "GlassCubeLabelPendulum") {
                 LinearView_HKPendulum(sharedStatePendulum: sharedStatePendulum, invisibleButtons: [], startButtonID: 0, endButtonID: 1)
                     .frame(width: 1360 * 5, height: 888 * lengthMeter)
             }
            
             Attachment(id: "GlassCubeLabel") {
//
                 LinearViewHK3(sharedState: sharedState, invisibleButtons: [], startButtonID: 4, endButtonID: 7, musicName: "Move Sequence 02")
                     .frame(width: 1360 * lengthMeter, height: 438 * lengthMeter)
             }
             Attachment(id: "GlassCubeLabelSecond") {
//
                 LinearViewHK3(sharedState: sharedState, invisibleButtons: [], startButtonID: 0, endButtonID: 3, musicName: "Move Sequence 02")
                     .frame(width: 1360 * lengthMeter, height: 438 * lengthMeter)
             }
             
             Attachment(id: "SpiralView") {
                                         LinearViewSpiral(sharedState: sharedStateSpiral, invisibleButtons: [], startButtonID: 0, endButtonID: 6, musicName: "Move Sequence 04")
                                             .frame(width: 1360 * lengthMeter * 2, height: 1360 * lengthMeter * 2) // Square frame for spiral
                                     }
            
            if appModel.showLinearView {
                Attachment(id: "LinearView") {
                    LinearView()
                       // .glassBackgroundEffect()
                }
            }
        }
        .task {
            await appModel.monitorSessionUpdates()
        }
        .task {
            await appModel.runSession()
        }
        .task {
            await appModel.processImageTrackingUpdates()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
