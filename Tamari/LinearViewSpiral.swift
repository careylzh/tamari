import SwiftUI
import AVFoundation

struct LinearViewSpiral: View {
    @ObservedObject var sharedState: SharedStateSpiral
    
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
    
    // Spiral parameters
    private let turns: Double = 2.0
    private let spiralSmoothness: Int = 200
    @State private var isHovering = false
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
    }
    
    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        let buttonRadius = geometry.size.width / 10
        
        ZStack {
            backgroundSpiral(buttonRadius: buttonRadius)
            trailPath()
            buttonLayer(geometry: geometry, buttonRadius: buttonRadius)
            trailDots(buttonRadius: buttonRadius)
            movingCircle(buttonRadius: buttonRadius)
        }
        .onAppear {
            setupView(geometry: geometry, buttonRadius: buttonRadius)
        }
        .onChange(of: sharedState.triggerID) { newID in
            handleTriggerChange(newID: newID, geometry: geometry)
        }
        .onDisappear {
            engine.stop()
        }
    }
    
    @ViewBuilder
    private func backgroundSpiral(buttonRadius: CGFloat) -> some View {
        Spiral(paddingAdd: buttonRadius)
            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
    }
    
    @ViewBuilder
    private func trailPath() -> some View {
        Path { path in
            if let firstPoint = trailPositions.first {
                path.move(to: firstPoint)
                for point in trailPositions.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .opacity(0.8)
        .animation(.easeOut(duration: 0.2), value: trailPositions.count)
    }
    
    @ViewBuilder
    private func buttonLayer(geometry: GeometryProxy, buttonRadius: CGFloat) -> some View {
        ForEach(startButtonID...endButtonID, id: \.self) { buttonID in
            buttonView(buttonID: buttonID, geometry: geometry, buttonRadius: buttonRadius)
        }
    }
    
    @ViewBuilder
    private func buttonView(buttonID: Int, geometry: GeometryProxy, buttonRadius: CGFloat) -> some View {
        Group {
            if let position = buttonPositions[buttonID] {
                let distance = sqrt(pow(currentX - position.x, 2) + pow(currentY - position.y, 2))
                let isCircleNearButton = distance < 50
                let isVisible = isCircleNearButton && buttonID == sharedState.triggerID && !invisibleButtons.contains(buttonID)
                
                ZStack {
                    mainButton(isVisible: isVisible, buttonRadius: buttonRadius, position: position, geometry: geometry, buttonID: buttonID)
                    
                    if isVisible {
                        pulseCircle(buttonRadius: buttonRadius)
                    }
                }
                .position(position)
            }
        }
    }
    
    @ViewBuilder
    private func mainButton(isVisible: Bool, buttonRadius: CGFloat, position: CGPoint, geometry: GeometryProxy, buttonID: Int) -> some View {
        ButtonView(isActive: isVisible, radius: buttonRadius)
            .scaleEffect(isVisible ? 0.6 : 1.0)
            .opacity(isVisible ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 2), value: isVisible)
            .onTapGesture {
                handleButtonTap(buttonID: buttonID, position: position, geometry: geometry, isVisible: isVisible)
            }
    }
    
    @ViewBuilder
    private func pulseCircle(buttonRadius: CGFloat) -> some View {
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
            .onHover { hovering in
                withAnimation(.spring()) {
                    isHovering = hovering
                }
                print("hovered")
            }
    }
    
    @ViewBuilder
    private func trailDots(buttonRadius: CGFloat) -> some View {
        ForEach(0..<trailPositions.count, id: \.self) { index in
            let progress = CGFloat(index) / CGFloat(trailPositions.count)
            let dotSize = progress * buttonRadius / 4.5
            
            Circle()
                .fill(.blue)
                .frame(width: dotSize, height: dotSize)
                .opacity(0.5 * progress)
                .position(trailPositions[index])
        }
    }
    
    @ViewBuilder
    private func movingCircle(buttonRadius: CGFloat) -> some View {
        let triggerInRange = (startButtonID...endButtonID).contains(sharedState.triggerID)
        let previousInRange = (startButtonID...endButtonID).contains(sharedState.triggerID - 1)
        
        if triggerInRange || previousInRange {
            Circle()
                .fill(.blue)
                .frame(width: buttonRadius/4, height: buttonRadius/4)
                .allowsHitTesting(false)
                .position(x: currentX, y: currentY)
        }
    }
    
    private func setupView(geometry: GeometryProxy, buttonRadius: CGFloat) {
        let points = computeButtonPointsAlongSpiral(in: geometry, radius: buttonRadius)
        for (index, point) in points.enumerated() {
            buttonPositions[startButtonID + index] = point
        }
        
        if let initialPosition = buttonPositions[sharedState.visitedButtons.first!] {
            currentX = initialPosition.x
            currentY = initialPosition.y
        }
        
        setupAudioEngine()
    }
    
    private func handleTriggerChange(newID: Int, geometry: GeometryProxy) {
        let previousID = sharedState.reversed ? newID + 1 : newID - 1
        if let fromPosition = buttonPositions[previousID],
           let toPosition = buttonPositions[newID] {
            moveCircleAlongSpiral(from: fromPosition, to: toPosition, in: geometry)
        }
    }
    
    private func handleButtonTap(buttonID: Int, position: CGPoint, geometry: GeometryProxy, isVisible: Bool) {
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
    
    // MARK: - Helpers

    private func computeButtonPointsAlongSpiral(in geometry: GeometryProxy, radius: CGFloat) -> [CGPoint] {
        let buttonCount = endButtonID - startButtonID + 1
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - radius - 20

        var points: [CGPoint] = []
        for i in 0..<buttonCount {
            let linearProgress = Double(i) / Double(max(buttonCount - 1, 1))

            // Apply a diminishing function (e.g., square root)
            let diminishingProgress = sqrt(linearProgress)

            // Now, use diminishingProgress instead of the original progress
            let currentRadius = maxRadius * diminishingProgress
            let angle = turns * 2.0 * .pi * diminishingProgress // Follow spiral path
            
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
    
    private func getPointOnSpiral(progress: Double, in geometry: GeometryProxy, radius: CGFloat) -> CGPoint {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - radius - 20
        
        let currentRadius = maxRadius * progress
        let angle = turns * 2.0 * .pi * progress
        
        let x = center.x + currentRadius * cos(angle)
        let y = center.y + currentRadius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
    
    private func moveCircleAlongSpiral(from: CGPoint, to: CGPoint, in geometry: GeometryProxy) {
        let startTime = Date()
        isAnimating = true
        
        trailPositions.removeAll()
        
        // Find the progress values for from and to positions
        let fromProgress = findProgressForPosition(from, in: geometry, radius: geometry.size.width / 10)
        let toProgress = findProgressForPosition(to, in: geometry, radius: geometry.size.width / 10)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { t in
            let elapsed = Date().timeIntervalSince(startTime)
            let animProgress = min(elapsed / animationDuration, 1.0)
            
            // Interpolate along spiral path
            let currentProgress = fromProgress + (toProgress - fromProgress) * animProgress
            let spiralPoint = getPointOnSpiral(progress: currentProgress, in: geometry, radius: geometry.size.width / 10)
            
            currentX = spiralPoint.x
            currentY = spiralPoint.y
            
            trailPositions.append(CGPoint(x: currentX, y: currentY))
            
            if trailPositions.count > 60 {
                trailPositions.removeFirst()
            }
            
            if animProgress >= 1.0 {
                t.invalidate()
                isAnimating = false
                
                Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { fadeOutTimer in
                    if trailPositions.count > 2 {
                        trailPositions.removeFirst()
                    } else {
                        fadeOutTimer.invalidate()
                    }
                }
            }
        }
    }
    
    private func findProgressForPosition(_ position: CGPoint, in geometry: GeometryProxy, radius: CGFloat) -> Double {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let distance = sqrt(pow(position.x - center.x, 2) + pow(position.y - center.y, 2))
        let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - radius - 20
        
        return min(Double(distance / maxRadius), 1.0)
    }
    
    // MARK: - Spatial Audio Functions
    private func setupAudioEngine() {
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
        
        engine.attach(playerNode)
        engine.attach(environmentNode)
        
        engine.connect(playerNode, to: environmentNode, format: audioFile?.processingFormat)
        
        engine.connect(environmentNode, to: engine.mainMixerNode, format: environmentNode.outputFormat(forBus: 0))

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
        
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 1.0)
    }

    private func playSound(at position: CGPoint, in geometry: GeometryProxy) {
        guard let audioFile = audioFile else {
            print("Audio file not loaded.")
            return
        }
        
        let normalizedX = (position.x / geometry.size.width) * 2 - 1
        let normalizedY = (position.y / geometry.size.height) * 2 - 1
        
        playerNode.position = AVAudio3DPoint(x: Float(normalizedX), y: Float(normalizedY), z: 0)
        
        playerNode.scheduleFile(audioFile, at: nil) {
        }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        playerNode.play()
    }
}
