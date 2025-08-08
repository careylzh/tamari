//
//  ToggleImmersiveSpaceButton.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(spacing: 20) {
            // Only show toggle button when immersive space is closed or in transition to open
            if appModel.immersiveSpaceState != .open {
                Button {
                    Task { @MainActor in
                        switch appModel.immersiveSpaceState {
                            case .open:
                                // This case will no longer be reachable since button is hidden when open
                                print("button triggered")
                                appModel.immersiveSpaceState = .inTransition
                                await dismissImmersiveSpace()
                                // Don't set immersiveSpaceState to .closed because there
                                // are multiple paths to ImmersiveView.onDisappear().
                                // Only set .closed in ImmersiveView.onDisappear().

                            case .closed:
                                appModel.immersiveSpaceState = .inTransition
                                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                                    case .opened:
                                        // Don't set immersiveSpaceState to .open because there
                                        // may be multiple paths to ImmersiveView.onAppear().
                                        // Only set .open in ImmersiveView.onAppear().
                                        break

                                    case .userCancelled, .error:
                                        // On error, we need to mark the immersive space
                                        // as closed because it failed to open.
                                        fallthrough
                                    @unknown default:
                                        // On unknown response, assume space did not open.
                                        appModel.immersiveSpaceState = .closed
                                }

                            case .inTransition:
                                // This case should not ever happen because button is disabled for this case.
                                break
                        }
                    }
                } label: {
                    Text("Show Immersive Space")
                }
                .disabled(appModel.immersiveSpaceState == .inTransition)
                .animation(.none, value: 0)
                .fontWeight(.semibold)
            }
            
            // Show control panel when immersive space is open
            if appModel.immersiveSpaceState == .open {
                ControlPanelView()
            }
        }
    }
}
