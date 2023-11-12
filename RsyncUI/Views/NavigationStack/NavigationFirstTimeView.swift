//
//  NavigationFirstTimeView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import ConfettiSwiftUI
import SwiftUI

struct NavigationFirstTimeView: View {
    @State private var counter: Int = 0

    let info: String = "https://rsyncui.netlify.app/post/important/"
    let add: String = "https://rsyncui.netlify.app/post/addconfigurations/"

    var body: some View {
        VStack {
            Text("Welcome to RsyncUI")
                .font(.title)

            imagersyncosx

            Text("")
            Text("Please read and understand the information below. There is more info")
            Text("selecting Important. Setting the wrong parameters to rsync can result in")
            Text("deleted data. RsyncUI will NOT stop you from doing so. That is why it is very")
            Text("important to execute a simulated run and inspect what happens before a real run.")

            HStack {
                Button("Important") { openimportantinfo() }
                    .buttonStyle(ColorfulButtonStyle())

                Button("Add tasks") { openaboutadd() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .padding()
        .onAppear {
            counter += 1
        }
        .onDisappear {
            SharedReference.shared.firsttime = false
        }
        .confettiCannon(counter: $counter, num: 100, 
                        openingAngle: Angle(degrees: 0),
                        closingAngle: Angle(degrees: 360),
                        radius: 200)
    }

    var imagersyncosx: some View {
        Image("rsyncosx")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 64)
    }

    func openimportantinfo() {
        NSWorkspace.shared.open(URL(string: info)!)
    }

    func openaboutadd() {
        NSWorkspace.shared.open(URL(string: add)!)
    }
}
