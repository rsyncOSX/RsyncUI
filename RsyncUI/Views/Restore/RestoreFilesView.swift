//
//  RestoreFilesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/02/2023.
//

import SwiftUI

struct RestoreFilesView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @StateObject var restorefilelist = ObserveableRestoreFilelist()
    @Binding var selectrowforrestore: String
    @Binding var filterstring: String

    @State private var selection: String?
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var config: Configuration?

    var body: some View {
        VStack {
            Text("Restore file list")
                .font(.title2)
                .padding()

            List(listitems, id: \.self, selection: $selection.onChange {
                selectrowforrestore = selection ?? ""
            }) { line in
                Text(line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            if restorefilelist.gettingfilelist == true { ProgressView() }

            if focusaborttask { labelaborttask }

            HStack {
                Spacer()

                TextField("Search", text: $restorefilelist.filterstring)

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .onAppear {
            Task {
                if let config = config {
                    if filterstring.isEmpty == false {
                        restorefilelist.filterstring = filterstring
                    }
                    await restorefilelist.validatetaskandgetfilelist(config)
                }
            }
        }
        .onDisappear {
            if SharedReference.shared.process != nil {
                _ = InterruptProcess()
            }
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var listitems: [String] {
        return restorefilelist.getoutput() ?? []
    }

    func abort() {
        _ = InterruptProcess()
    }
}
