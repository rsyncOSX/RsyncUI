//
//  AllOutputView.swift
//  RsyncUImenu
//
//  Created by Thomas Evensen on 12/11/2025.
//

import Observation
import RsyncProcess
import SwiftUI

struct AllOutputView: View {
    // The generated observable model from @Observable should be usable as an observable object here.
    // Using @ObservedObject to reference the shared singleton.
    @State private var model = PrintLines.shared

    var body: some View {
        // NavigationView {
        VStack {
            List(model.output, id: \.self) { line in
                Text(line)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }

            ConditionalGlassButton(
                systemImage: "trash",
                text: "Clear",
                helpText: "Clear output"
            ) {
                Task { @MainActor in
                    model.clear()
                }
            }
        }
        .padding()
    }
}
