//
//  ImmersivePostersApp.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import SwiftUI
import OSLog

@main
struct TamariApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    print("opening space")
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    
                }
//            ImageTrackingImmersiveView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}

@MainActor
let logger = Logger(subsystem: "com.sarang.PostersOfTheFuture", category: "general")
