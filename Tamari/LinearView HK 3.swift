import SwiftUI
import AVFoundation

struct LinearViewHK3: View {
    @ObservedObject var sharedState: SharedState
    
    let invisibleButtons: [Int]
    let startButtonID: Int
    let endButtonID: Int
    let musicName: String

    let animationDuration: Double = 3.0

    @State private var currentX: CGFloat = 0
    @State private var currentY: CGFloat = 0
    @State private var timer: Timer?
    @State private var isAnimating = false
    @State private var buttonPositions: [Int: CGPoint] = [:]
    @State private var trailPositions: [CGPoint] = []
    @State private var pulseScale: CGFloat = 1.0
    
    @State private var engine = AVAudioEngine()
    @State private var environmentNode = AVAudioEnvironmentNode()
    @State private var playerNode = AVAudioPlayerNode()
    @State private var audioFile: AVAudioFile?
    @State private var isHovering = false
    
    // Add edge positions
    @State private var leftEdgePosition: CGPoint = .zero
    @State private var rightEdgePosition: CGPoint = .zero

    var body: some View {
        
        GeometryReader { geometry in
            
            let buttonRadius = geometry.size.width / 10
            ZStack {
                LinearLine()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // New: The line that shows the path of the blue circle
                Path { path in
                    // Start from left edge if we're at the beginning
                    if sharedState.triggerID == startButtonID && !sharedState.visitedButtons.contains(startButtonID) {
                        path.move(to: leftEdgePosition)
                    } else if buttonPositions[startButtonID] != nil {
                        path.move(to: buttonPositions[startButtonID]!)
                    }
                    
                    if let firstPoint = trailPositions.first {
                        for point in trailPositions.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.gray, style: StrokeStyle(lineWidth: buttonRadius / 4, lineCap: .round, lineJoin: .round))
                .opacity(0.2)
                .animation(.easeOut(duration: 0.2), value: trailPositions.count)
                
                ForEach(startButtonID...endButtonID, id: \.self) { buttonID in
                    if let position = buttonPositions[buttonID] {
                        
                        
                        let distance = sqrt(pow(currentX - position.x, 2) + pow(currentY - position.y, 2))
                        let isCircleNearButton = distance < 10
                        
                        let isVisible = isCircleNearButton && buttonID == sharedState.triggerID && !invisibleButtons.contains(buttonID)
                        let isVisited = sharedState.visitedButtons.contains(buttonID)

                        ZStack {
                            ButtonView(isActive: isVisible, radius: buttonRadius)
                                .scaleEffect(isVisible ? 0.6 : 1.0)
                                .opacity(isVisible ? 0.4 : (isHovering ? 0.8 : 1.0))
                                .animation(.easeInOut(duration: 2), value: isVisible)
                                .animation(.easeInOut(duration: 0.5), value: isHovering)
                                .onTapGesture {
                                    guard !isAnimating else { return }
                                    guard isVisible else { return }
                                    
                                    playSound(at: position, in: geometry)
                                    
                                    print(10 + sharedState.triggerID)
                                    if buttonID == sharedState.triggerID {
                                        withAnimation(.easeInOut(duration: 2)) {
                                            sharedState.updateTriggerID()
                                        }
                                    }
                                }
                                .onHover { hovering in
                                    withAnimation(.spring()) {
                                        isHovering = hovering
                                    }
                                    print("hovered")
                                }
                            
                            if isVisible {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: buttonRadius)
                                    .scaleEffect(pulseScale)
                                    .opacity(1.5 - pulseScale)
                                    .animation(
                                        Animation.easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true),
                                        value: pulseScale
                                    )
                                    .onAppear {
                                        pulseScale = 1.2
                                    }
                                    .onDisappear {
                                        pulseScale = 1.0
                                    }
                            }
                        }
                        .position(position)
                    }
                }
                
                // The blue ghosting circles are still here for the "ghosting" effect
                ForEach(0..<trailPositions.count, id: \.self) { index in
                    let progress = CGFloat(index) / CGFloat(trailPositions.count)
                    Circle()
                        .fill(.blue)
                        .frame(width: progress * buttonRadius / 5, height: progress * buttonRadius / 5)
                        .opacity(0.1 * progress)
                        .position(trailPositions[index])
                }
                
                if (startButtonID...endButtonID).contains(sharedState.triggerID)
//                    || (startButtonID...endButtonID).contains((sharedState.triggerID - 1))
                {
                    Circle()
                        .fill(.blue)
                        .frame(width: buttonRadius/4, height: buttonRadius/4)
                        .allowsHitTesting(false)
                        .position(x: currentX, y: currentY)
                }
            }
            .onAppear {
                let points = computeButtonPoints(in: geometry, radius: buttonRadius)
                for (index, point) in points.enumerated() {
                    buttonPositions[startButtonID + index] = point
                }
                
                // Set edge positions
                leftEdgePosition = CGPoint(x: 0, y: geometry.size.height / 2)
                rightEdgePosition = CGPoint(x: geometry.size.width, y: geometry.size.height / 2)
                
                // Start at left edge instead of first button position
                currentX = leftEdgePosition.x
                currentY = leftEdgePosition.y
                
                playerNode.volume = 0.7
                
                // Trigger initial movement if this view contains the current triggerID
                if sharedState.triggerID >= startButtonID && sharedState.triggerID <= endButtonID {
                    if let targetPosition = buttonPositions[sharedState.triggerID] {
                        // Small delay to ensure everything is set up
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            moveCircle(from: leftEdgePosition, to: targetPosition, in: geometry)
                        }
                    }
                }
            }
            .onChange(of: sharedState.triggerID) { newID in
                // Only handle movement if the new ID is within this view's range
                guard newID >= startButtonID && newID <= endButtonID else { return }
                
                let previousID = sharedState.reversed ? newID + 1 : newID - 1
                
                // Determine source and destination positions
                var fromPosition: CGPoint
                var toPosition: CGPoint
                
                if newID == startButtonID && previousID < startButtonID {
                    // Coming from outside (left edge) to first button
                    fromPosition = leftEdgePosition
                    toPosition = buttonPositions[newID] ?? leftEdgePosition
                } else if previousID == endButtonID && newID > endButtonID {
                    // Going from last button to outside (right edge)
                    fromPosition = buttonPositions[previousID] ?? rightEdgePosition
                    toPosition = rightEdgePosition
                } else if buttonPositions[previousID] != nil && buttonPositions[newID] != nil {
                    // Normal button-to-button movement within this view
                    fromPosition = buttonPositions[previousID]!
                    toPosition = buttonPositions[newID]!
                } else {
                    // Fallback: no movement
                    return
                }
                
                moveCircle(from: fromPosition, to: toPosition, in: geometry)
            }
            .onAppear {
                let points = computeButtonPoints(in: geometry, radius: buttonRadius)
                            for (index, point) in points.enumerated() {
                                buttonPositions[startButtonID + index] = point
                            }
                            
                            // Set edge positions
                            leftEdgePosition = CGPoint(x: 0, y: geometry.size.height / 2)
                            rightEdgePosition = CGPoint(x: geometry.size.width, y: geometry.size.height / 2)
                            
                            // Start at left edge
                            currentX = leftEdgePosition.x
                            currentY = leftEdgePosition.y
                            
                            // Setup the audio engine and nodes when the view appears
                            setupAudioEngine()
                        }
            .onDisappear {
                            // Stop and reset the audio engine when the view disappears
                            engine.stop()
                        }
        }
    }
    
    // MARK: - Helpers

    private func computeButtonPoints(in geometry: GeometryProxy, radius: CGFloat) -> [CGPoint] {
        let buttonCount = endButtonID - startButtonID + 1
        let width = geometry.size.width
        let height = geometry.size.height
        let midY = height / 2

        let paddedWidth = width - 2 * radius
        
        let xPositions = stride(from: 0.0, through: 1.0, by: 1.0 / CGFloat(buttonCount - 1)).map {
            CGFloat($0) * paddedWidth + radius
        }

        return xPositions.map { x in
            return CGPoint(x: x, y: midY)
        }
    }
    
    private func moveCircle(from: CGPoint, to: CGPoint, in geometry: GeometryProxy) {
        let fromX = from.x
        let toX = to.x
        let startTime = Date()
        isAnimating = true
        
        // Clear the trail at the start of a new movement
        trailPositions.removeAll()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { t in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / animationDuration, 1.0)
            
            let x = fromX + CGFloat(progress) * (toX - fromX)
            let y = from.y
            
            currentX = x
            currentY = y
            
            trailPositions.append(CGPoint(x: currentX, y: currentY))
            
            // This keeps the trail to a fixed length, creating a ghosting effect
            if trailPositions.count > 120 {
                trailPositions.removeFirst()
            }
            
            if progress >= 1.0 {
                t.invalidate()
                isAnimating = false
                
                // Start a new timer to fade out the trail
                Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { fadeOutTimer in
                    // Only remove points if there's more than one left
                    if trailPositions.count > 2 {
                        // Remove the oldest point from the trail
                        trailPositions.removeFirst()
                    } else {
                        // Stop the fade-out timer once only one point is left
                        fadeOutTimer.invalidate()
                    }
                }
            }
        }
    }
    
    // MARK: - Spatial Audio Functions
        private func setupAudioEngine() {
            // Load the audio file (make sure it's mono for best spatial results)
            guard let url = Bundle.main.url(forResource: musicName, withExtension: "mp3") else {
                print("Sound file not found.")
                return
            }
            do {
                self.audioFile = try AVAudioFile(forReading: url)
            } catch {
                print("Error loading audio file: \(error.localizedDescription)")
                return
            }
            
            // Connect nodes
            engine.attach(playerNode)
            engine.attach(environmentNode)
            
            // Connect the player node to the environment node's input bus
            engine.connect(playerNode, to: environmentNode, format: audioFile?.processingFormat)
            
            // Connect the environment node to the main output
            engine.connect(environmentNode, to: engine.mainMixerNode, format: environmentNode.outputFormat(forBus: 0))

            do {
                try engine.start()
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
            
            // Set the listener position
            // We'll place the listener slightly "in front" of the 2D plane
            environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 1.0)
        }

        private func playSound(at position: CGPoint, in geometry: GeometryProxy) {
            guard let audioFile = audioFile else {
                print("Audio file not loaded.")
                return
            }
            
            // Position the sound source in 3D space relative to the listener
            let normalizedX = (position.x / geometry.size.width) * 2 - 1
            let normalizedY = (position.y / geometry.size.height) * 2 - 1
            
            // The Z-axis determines how "close" the sound is. We'll set it to 0 for a 2D plane.
            playerNode.position = AVAudio3DPoint(x: Float(normalizedX), y: Float(normalizedY), z: 0)
            
            playerNode.scheduleFile(audioFile, at: nil) {
                // This completion handler is called after the sound finishes playing
            }
            
            if !engine.isRunning {
                try? engine.start()
            }
            
            playerNode.play()
        }
}
