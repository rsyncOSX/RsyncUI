//
//  RsyncRealtimeView.swift
//  RsyncUImenu
//
//  Created by Thomas Evensen on 12/11/2025.
//

import Observation
import RsyncProcess
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
                ConditionalGlassButton(
                    systemImage: "eyes.inverse",
                    text: "View",
                    helpText: "Enable capture rsync output",
                    textcolor: isTappedview
                ) {
                    Task {
                        isTappedview.toggle()
                        guard isTappedview else {
                            await RsyncOutputCapture.shared.disable()
                            return
                        }

                        if await RsyncOutputCapture.shared.isCapturing() {
                            isTappedfile = false
                            await RsyncOutputCapture.shared.disable()
                        }
                        await RsyncOutputCapture.shared.enable()
                    }
                }

                ConditionalGlassButton(
                    systemImage: "square.and.arrow.down.badge.checkmark",
                    text: "File",
                    helpText: "Enable capture rsync output",
                    textcolor: isTappedfile
                ) {
                    Task {
                        isTappedfile.toggle()
                        guard isTappedfile else {
                            await RsyncOutputCapture.shared.disable()
                            return
                        }
                        if await RsyncOutputCapture.shared.isCapturing() {
                            isTappedview = false
                            await RsyncOutputCapture.shared.disable()
                        }
                        if let logURL = URL.userHomeDirectoryURLPath?.appendingPathComponent("rsync-output.log") {
                            await RsyncOutputCapture.shared.enable(writeToFile: logURL)
                        }
                    }
                }

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
