import SwiftUI

struct Spiral: Shape {
    let turns: Double = 2.0 // Number of complete rotations
    let smoothness: Int = 200 // Number of points for smooth curve
    let paddingAdd: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let maxRadius = min(rect.width, rect.height) / 2 - paddingAdd // Add some padding
        
        // Create smooth spiral curve
        for i in 0...smoothness {
            let progress = Double(i) / Double(smoothness)
            let currentRadius = maxRadius * progress
            let angle = turns * 2.0 * .pi * progress // This creates the spiral
            
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            
            let point = CGPoint(x: x, y: y)

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}
