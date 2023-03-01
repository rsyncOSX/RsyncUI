//
//  RestoreFilesView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/02/2023.
//

import SwiftUI

struct RestoreFilesView: View {
    @StateObject var restorefilelist = ObserveableRestoreFilelist()
    @Binding var isPresented: Bool
    @Binding var selectrowforrestore: String
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
                selectrowforrestore = selection ?? ""
            }) { line in
                Text(line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            if restorefilelist.gettingfilelist == true {
                ZStack {
                    ProgressView()
                        .frame(width: 50.0, height: 50.0)
                }
            }

            if focusaborttask { labelaborttask }

            HStack {
                Spacer()

                // TextField("Search", text: $restorefilelist.filterstring)

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .searchable(text: $restorefilelist.filterstring.onChange {
            restorefilelist.inputchangedbyuser = true
        })
        .onAppear {
            Task {
                if let config = config {
                    await restorefilelist.validatetaskandgetfilelist(config)
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
        if selectrowforrestore == "" || selectrowforrestore == " " {
            return restorefilelist.getoutput() ?? []
        } else {
            return (restorefilelist.getoutput() ?? []).filter { $0.contains(restorefilelist.filterstring) }
        }
    }

    func dismissview() {
        isPresented = false
    }

    func abort() {
        _ = InterruptProcess()
    }
}
