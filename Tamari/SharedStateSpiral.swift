import SwiftUI
import Combine

class SharedStateSpiral: ObservableObject {
    @Published var triggerID: Int = 0 // The ID of the next button to activate
    @Published var visitedButtons: [Int] = [0] // Stores IDs of buttons that have been visited
    @Published var reversed: Bool = false // Controls the direction of the animation

    func updateTriggerID() {
        print("triggered")
        if reversed {
            if triggerID > 0 {
                
                // If moving backward and not at the start, just decrement
                triggerID -= 1
            } else {
                // If at the start, flip direction and move forward
                reversed = false
                triggerID += 1
            }
        } else {
            if triggerID < 6 {
                // If moving forward and not at the end, just increment
                
                triggerID += 1
            } else {
                // If at the end, flip direction and move backward
                reversed = true
                triggerID -= 1
            }
        }
        
        // This logic to add visited buttons still works as intended
        if !visitedButtons.contains(triggerID) {
            visitedButtons.append(triggerID)
            visitedButtons.sort()
        }
    }
}
