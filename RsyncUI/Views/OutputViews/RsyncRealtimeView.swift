//
//  RsyncRealtimeView.swift
//  RsyncUImenu
//
//  Created by Thomas Evensen on 12/11/2025.
//

import RsyncProcessStreaming
import SwiftUI

struct RsyncRealtimeView: View {
    // The generated observable model from @Observable should be usable as an observable object here.
    // Using @ObservedObject to reference the shared singleton.
    @State private var model = PrintLines.shared
    @State private var isTappedfile = false
    @State private var isTappedview = false

    var body: some View {
        // NavigationView {
        VStack {
            List(model.output, id: \.self) { line in
                Text(line)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }
            
            HStack {
                Spacer()

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
        }
        .padding()
        .onDisappear {
            Task {
                await RsyncOutputCapture.shared.disable()
            }
        }
    }
}
