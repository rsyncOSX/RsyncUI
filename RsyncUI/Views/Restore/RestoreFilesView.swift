//
//  RestoreFilesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/02/2023.
//

import SwiftUI

struct RestoreFilesView: View {
    @StateObject var restore = ObserveableRestore()
    @Binding var isPresented: Bool
    @Binding var valueselectedrow: String
    @Binding var config: Configuration?

    @State private var selection: String?
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var body: some View {
        VStack {
            Text("Restore file list")
                .font(.title2)
                .padding()

            List(listitems, id: \.self, selection: $selection.onChange {
                valueselectedrow = selection ?? ""
            }) { line in
                Text(line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            if restore.gettingfilelist == true {
                ZStack {
                    ProgressView()
                        .frame(width: 50.0, height: 50.0)
                }
            }

            if focusaborttask { labelaborttask }

            HStack {
                Spacer()

                TextField("Search", text: $valueselectedrow)

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .searchable(text: $restore.filterstring.onChange {
            restore.inputchangedbyuser = true
        })
        .onAppear {
            Task {
                if let config = config {
                    await restore.validatetaskandgetfilelist(config)
                }
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
        if valueselectedrow == "" || valueselectedrow == " " {
            return restore.getoutput() ?? []
        } else {
            return (restore.getoutput() ?? []).filter { $0.contains(valueselectedrow) }
        }
    }

    func dismissview() {
        isPresented = false
    }

    func abort() {
        _ = InterruptProcess()
    }
}
