//
//  RsyncCommandView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/01/2021.
//

import SwiftUI

struct RsyncCommandView: View {
    @State var selectedrsynccommand: RsyncCommand = .synchronizeData
    @State private var otherselectedrsynccommand = OtherRsyncCommand.listRemoteFiles

    let config: SynchronizeConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                Picker("Action", selection: $selectedrsynccommand) {
                    ForEach(RsyncCommand.allCases) { command in
                        Text(LocalizedStringKey(command.description)).tag(command)
                    }
                }
                CommandPreviewText(command: commandstringrsync ?? "")
            } label: {
                Label("Rsync command", systemImage: "terminal")
            }

            GroupBox {
                Picker("Action", selection: $otherselectedrsynccommand) {
                    ForEach(OtherRsyncCommand.allCases) { command in
                        Text(LocalizedStringKey(command.description)).tag(command)
                    }
                }
                CommandPreviewText(command: commandstringother)
            } label: {
                Label("Other commands", systemImage: "text.alignleft")
            }
        }
    }

    var commandstringrsync: String? {
        RsyncCommandtoDisplay(display: selectedrsynccommand,
                              config: config).rsynccommand
    }

    var commandstringother: String {
        OtherRsyncCommandtoDisplay(display: otherselectedrsynccommand,
                                   config: config).command
    }
}

private struct CommandPreviewText: View {
    let command: String
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: command)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Copy", systemImage: copied ? "checkmark" : "doc.on.doc", action: copy)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Copy command")
                .disabled(command.isEmpty)
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
        .onChange(of: command) { copied = false }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(command, forType: .string)
    }
}
