import SwiftUI
import Combine

class SharedStatePendulum: ObservableObject {
    @Published var triggerID: Int = 0 // The ID of the next button to activate
    @Published var visitedButtons: [Int] = [0] // Stores IDs of buttons that have been visited
    @Published var reversed: Bool = false // Controls the direction of the animation
    @Published var movementCount: Int = 0 // Tracks cumulative number of movements

    func updateTriggerID() {
        // Increment movement counter
        movementCount += 1
        
        if triggerID == 0{
            reversed = false
               triggerID = 1
            print("toggled")
           
        }else{
            reversed = true
            triggerID = 0}
        
        // This logic to add visited buttons still works as intended
        if !visitedButtons.contains(triggerID) {
            visitedButtons.append(triggerID)
            visitedButtons.sort()
        }
    }
}
