import SwiftUI
import Combine



class SharedStateSmile: ObservableObject {
    @Published var triggerID: Int = 0
    
    // We'll use this property to trigger the animation.
    @Published var animationTrigger: Bool = false

    func updateTriggerID() {
        triggerID = (triggerID == 0) ? 1 : 0
        animationTrigger.toggle() // Toggle this to trigger the animation
    }
}
