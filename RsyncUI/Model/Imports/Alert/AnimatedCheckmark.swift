//
//  AnimatedCheckmark.swift
//

import SwiftUI

struct AnimatedCheckmark: View {
    /// Checkmark color
    var color: Color = .black

    /// Checkmark color
    var size: Int = 50

    var height: CGFloat {
        return CGFloat(size)
    }

    var width: CGFloat {
        return CGFloat(size)
    }

    @State private var percentage: CGFloat = .zero

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height / 2))
            path.addLine(to: CGPoint(x: width / 2.5, y: height))
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        .trim(from: 0, to: percentage)
        .stroke(
            color, style: StrokeStyle(lineWidth: CGFloat(size / 8), lineCap: .round, lineJoin: .round)
        )
        .animation(Animation.spring().speed(0.75).delay(0.25), value: percentage)
        .onAppear {
            percentage = 1.0
        }
        .frame(width: width, height: height, alignment: .center)
    }
}
