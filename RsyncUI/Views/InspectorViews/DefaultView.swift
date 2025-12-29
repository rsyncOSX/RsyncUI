//
//  DefaultView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/12/2025.
//

import SwiftUI

struct DefaultView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var togglechooseview: Bool = true

    var body: some View {
        Group {
            if togglechooseview {
                AddTaskView(rsyncUIdata: rsyncUIdata,
                            togglechooseview: $togglechooseview)
            } else {
                RsyncParametersView(rsyncUIdata: rsyncUIdata,
                                    togglechooseview: $togglechooseview)
            }
        }
    }
}
