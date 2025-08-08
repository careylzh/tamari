//
//  SineView.swift
//  ButtonTest
//
//  Created by Gabriel Elijah Lipkowitz gel on 6/8/25.
//

import Foundation
import SwiftUI

struct LinearLine: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
//        let step = 1.0
        let width = rect.width
        let height = rect.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        path.addLine(to: CGPoint(x: width, y: midY))

        return path
    }
}
