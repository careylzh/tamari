import SwiftUI

struct LinearView: View {
    let amplitude: CGFloat = 50
    let frequency: CGFloat = 2
    let animationDuration: Double = 1.0

    @State private var activeIndex: Int = 0
    @State private var currentX: CGFloat = 0
    @State private var currentY: CGFloat = 0
    @State private var buttonVisible: [Bool] = [true, false, false, false]
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var fromX: CGFloat = 0
    @State private var toX: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            let buttonPoints = computeButtonPoints(in: geometry)

            ZStack {
                // Draw line or sine wave
                LinearLine()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)

                // Draw buttons
                ForEach(0..<buttonPoints.count, id: \.self) { i in
                    if buttonVisible[i] {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 100, height: 100)
                            .position(buttonPoints[i])
                            .onTapGesture {
                                guard !isAnimating else { return }
                                if i == activeIndex && i < buttonPoints.count - 1 {
                                    moveCircle(from: buttonPoints[i], to: buttonPoints[i + 1], in: geometry)
                                    activeIndex += 1
                                    buttonVisible[activeIndex] = true
                                    print("button clicked")
                                }
                            }
                    }
                }

                // Blue circle
                Circle()
                    .fill(.blue)
                    .frame(width: 20, height: 20)
                    .position(x: currentX, y: currentY)
            }
            .onAppear {
                let start = computeButtonPoints(in: geometry).first ?? .zero
                currentX = start.x
                currentY = start.y
            }
        }
        .frame(width: 1280, height: 200)
        .padding()
        .border(Color.red, width:2)
    }
        
    
//    private func resetState() {
////        activeIndex = 0
////        currentX = 0
////        currentY = 0
////        buttonVisible = [true, false, false, false]
////        fromX = 0
////        toX = 0
////        isAnimating = false
//        }

    // MARK: - Helpers

    private func computeButtonPoints(in geometry: GeometryProxy) -> [CGPoint] {
        let width = geometry.size.width
        let height = geometry.size.height
        let midY = height / 2
        let xPositions = stride(from: 0.0, through: 1.0, by: 1.0 / 3.0).map { CGFloat($0) * width }

        return xPositions.map { x in
//            let normalizedX = x / width
//            let angle = normalizedX * frequency * 2 * .pi
//            let y = midY - amplitude * sin(angle)  change to `midY` if you want straight line
            let y = midY // change to `midY` if you want straight line
            print("x: \(x), y:\(y)")
            return CGPoint(x: x, y: y)
        }
    }

    private func moveCircle(from: CGPoint, to: CGPoint, in geometry: GeometryProxy) {
        fromX = from.x
        toX = to.x
        startTime = Date()
        isAnimating = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            guard let startTime = startTime else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / animationDuration, 1.0)

            let width = geometry.size.width
            let height = geometry.size.height
            let midY = height / 2

            let x = fromX + CGFloat(progress) * (toX - fromX)
            let normalizedX = x / width
            let angle = normalizedX * frequency * 2 * .pi
//            let y = midY - amplitude * sin(angle) // if using sine curve
            let y = midY

            currentX = x
            currentY = y

            if progress >= 1.0 {
                t.invalidate()
                isAnimating = false
            }
        }
    }
}
