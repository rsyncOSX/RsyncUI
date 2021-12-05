//
//  FirsttimeView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/12/2021.
//

import SwiftUI

struct FirsttimeView: View {
    @Binding var dismiss: Bool
    // Which sidebar function
    @Binding var selection: NavigationItem?

    let info: String = "https://rsyncui.netlify.app/post/important/"
    let add: String = "https://rsyncui.netlify.app/post/addconfigurations/"

    var body: some View {
        VStack {
            Text("About RsyncUI and some important info")
                .font(.title)
            Text("")
            Text("Please read and understand the information below.")
            Text("Setting the wrong parameters to rsync can result in deleted data.")
            Text("RsyncUI will NOT stop you from doing so. That is why it is very important ")
            Text("to execute a simulated run and inspect what happens before a real run.")

            HStack {
                Button("Read") { openimportantinfo() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Add tasks") { openaboutadd() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Dismiss") { dismiss = false }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .onDisappear {
            SharedReference.shared.firsttime = false
            selection = .configurations
        }
        .frame(width: 800, height: 400)
    }

    func openimportantinfo() {
        NSWorkspace.shared.open(URL(string: info)!)
    }

    func openaboutadd() {
        NSWorkspace.shared.open(URL(string: add)!)
    }
}
