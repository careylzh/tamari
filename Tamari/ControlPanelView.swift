//
//  ControlPanelView.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import SwiftUI
import RealityKit

struct ControlPanelView: View {
    @Environment(AppModel.self) var appModel
    
    
    // Hardcoded positions relative to world origin
    private let cubePosition = SIMD3<Float>(0, 0, 0)
    private let scubePosition = SIMD3<Float>(0, 0, 0)
    private let lcubePosition = SIMD3<Float>(-1.5, -0.2, 0)
    
    // Track current button state
    @State private var currentButtonPressed: Int? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Control Panel")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            HStack(spacing: 15) {
                Button {
                    handleButtonPress(1)
                } label: {
                    Text("Pneumatic\nPendulum")
                        .frame(width: 180, height: 50)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    handleButtonPress(2)
                } label: {
                    Text("Spatial\nFlow")
                        .frame(width: 180, height: 50)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    handleButtonPress(3)
                } label: {
                    Text("Spiral\nSoothing")
                        .frame(width: 180, height: 50)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(minWidth: 300, minHeight: 150)
        .onAppear {
            setInitialPositions()
        }
    }
    
    private func setInitialPositions() {
        // Set hardcoded positions for all cubes
      
    }
    
    private func handleButtonPress(_ buttonNumber: Int) {
        print("Button \(buttonNumber) pressed")
        
        // If the same button is pressed again, do nothing
        if currentButtonPressed == buttonNumber {
            return
        }
        
        // First hide all cubes
        let hiddenPosition = SIMD3<Float>(0, 0, 1000)
        appModel.cube.transform.translation = hiddenPosition
        appModel.Scube.transform.translation = hiddenPosition
        appModel.Lcube.transform.translation = hiddenPosition
        
        // Then restore only the one that should remain visible
        switch buttonNumber {
        case 1:
            // Button 1: Restore cube to hardcoded position
            appModel.cube.transform.translation = cubePosition
            
        case 2:
            // Button 2: Restore Lcube to hardcoded position
            appModel.Lcube.transform.translation = lcubePosition
            
        case 3:
            // Button 3: Restore scube to hardcoded position
            appModel.Scube.transform.translation = scubePosition
            
        default:
            break
        }
        
        currentButtonPressed = buttonNumber
    }
}
