//
//  SidebarSnapshots.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SidebarSnapshotsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling

    @State private var selectedconfig: Configuration?
    @Binding var reload: Bool

    var body: some View {
        VStack {
            headingtitle

            SnapshotsView(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() })
        }
        .padding()
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("Snapshots", comment: "SidebarSnapshotsView"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
