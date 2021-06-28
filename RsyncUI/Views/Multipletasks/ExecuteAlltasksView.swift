//
//  ExecuteAlltasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 15/02/2021.
//

import SwiftUI

struct ExecuteAlltasksView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var selecteduuids: Set<UUID>
    @Binding var isPresented: Bool
    @Binding var presentestimatedsheetview: Bool

    var body: some View {
        VStack {
            header

            Spacer()

            HStack {
                Button("Execute all") { executeall() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Cancel") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    var header: some View {
        HStack {
            let message = "Execute all tasks" + "?"
            Text(message)
                .modifier(Tagheading(.title2, .center))
        }
        .padding()
    }

    func dismissview() {
        isPresented = false
    }

    func executeall() {
        selecteduuids.removeAll()
        for i in 0 ..< (rsyncUIdata.rsyncdata?.configurationData.getnumberofconfigurations() ?? 0) {
            if let id = rsyncUIdata.rsyncdata?.configurationData.getallconfigurations()?[i].id {
                selecteduuids.insert(id)
            }
        }
        isPresented = false
        presentestimatedsheetview = true
    }
}
