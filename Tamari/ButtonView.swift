import SwiftUI

struct ButtonView: View {
    let isActive: Bool
    let radius: CGFloat
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .background(
                // Extra blur layer underneath
                Circle()
                    .fill(.regularMaterial)
                    .blur(radius: 8)
            )
            .overlay(
                // Pastel gradient overlay
                Circle()
                    .fill(
                        !isActive ? LinearGradient(
                            colors: [
                                Color.blue.opacity(0.12),
                                Color.purple.opacity(0.08),
                                Color.pink.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : LinearGradient(
                            colors: [
                                Color.blue.opacity(0.0),
                                Color.purple.opacity(0.0),
                                Color.pink.opacity(0.0),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                            )
                    )
                    .blur(radius: 3)
            )
            .overlay(
                // Frosted glass effect with pastel tint
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.cyan.opacity(0.08),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 2)
            )
            .overlay(
                // Subtle inner border highlight with pastel edge
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.blue.opacity(0.2),
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 0.5)
            )
            .overlay(
                // Crisp outer border
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.33)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .frame(width: radius, height: radius)
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

//// MARK: - Preview
//struct ButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 40) {
//            ButtonView()
//            ButtonView()
//        }
//        .padding()
//        .preferredColorScheme(.dark)
//        .previewDisplayName("Dark Mode")
//
//        VStack(spacing: 40) {
//            ButtonView()
//            ButtonView()
//        }
//        .padding()
//        .preferredColorScheme(.light)
//        .previewDisplayName("Light Mode")
//    }
//}
