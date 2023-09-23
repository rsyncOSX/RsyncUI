//
//  AnimatedXmark.swift
//

import SwiftUI

struct AnimatedXmark: View {
    /// xmark color
    var color: Color = .black

    /// xmark size
    var size: Int = 50

    var height: CGFloat {
        return CGFloat(size)
    }

    var width: CGFloat {
        return CGFloat(size)
    }

    var rect: CGRect {
        return CGRect(x: 0, y: 0, width: size, height: size)
    }

    @State private var percentage: CGFloat = .zero

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxY, y: rect.maxY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        .trim(from: 0, to: percentage)
        .stroke(
            color,
            style: StrokeStyle(
                lineWidth: CGFloat(size / 8),
                lineCap: .round,
                lineJoin: .round
            )
        )
        .animation(Animation.spring().speed(0.75).delay(0.25), value: percentage)
        .onAppear {
            percentage = 1.0
        }
        .frame(width: width, height: height, alignment: .center)
    }
}
