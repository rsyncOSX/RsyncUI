//
//  AlltasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//

import Foundation
import SwiftUI

struct AlltasksView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Table(data) {
                TableColumn("Synchronize ID", value: \.backupID)
                    .width(min: 100, max: 200)
                TableColumn("Last") { data in
                    Text(data.dateRun ?? "")
                }
                .width(max: 120)
                TableColumn("Task", value: \.task)
                    .width(max: 80)
                TableColumn("Local catalog", value: \.localCatalog)
                    .width(min: 100, max: 300)
                TableColumn("Remote catalog", value: \.offsiteCatalog)
                    .width(min: 100, max: 300)
                TableColumn("Server", value: \.offsiteServer)
                    .width(max: 70)
            }
            .frame(width: 650, height: 500, alignment: .center)
            .foregroundColor(.blue)

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 500)
    }

    var data: [Configuration] {
        return Allprofilesandtasks().alltasks ?? []
    }
}

extension AlltasksView {
    func dismissview() {
        isPresented = false
    }
}
