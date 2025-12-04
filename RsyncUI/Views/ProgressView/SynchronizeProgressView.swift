//
//  SynchronizeProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/12/2025.
//

import SwiftUI

struct SynchronizeProgressView: View {
    let max: Double
    let progress: Double
    let statusText: String

    var body: some View {
        VStack(spacing: 20) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 12
                    )

                if max > 0 {
                    Circle()
                        .trim(from: 0, to: min(progress / max, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 12,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }

                VStack(spacing: 4) {
                    Text("\(Int(progress))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(countsDown: false))
                }
            }
            .frame(width: 160, height: 160)

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .animation(.default, value: progress)
    }
}
