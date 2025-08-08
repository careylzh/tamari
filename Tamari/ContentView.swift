//
//  ContentView.swift
//  ImmersivePosters
//
//  Created by Sarang Borude on 5/28/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?


    var body: some View {
        VStack {
            Text("Welcome to Immersive Posters!")

            ToggleImmersiveSpaceButton()
        }
        .padding()
        .onAppear { // Add this modifier
            playSound()
        }
    }
        
    private func playSound() {
        guard let url = Bundle.main.url(forResource: "Sequence 01", withExtension: "mp3") else {
            print("Startup sound file not found.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
