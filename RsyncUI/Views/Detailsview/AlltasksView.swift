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
                TableColumn("Profile") { data in
                    if markconfig(data) {
                        Text(data.profile ?? "")
                            .foregroundColor(.red)
                    } else {
                        Text(data.profile ?? "")
                    }
                }
                .width(min: 100, max: 200)
                TableColumn("Synchronize ID", value: \.backupID)
                    .width(min: 100, max: 200)
                TableColumn("Last") { data in
                    if markconfig(data) {
                        Text(data.dateRun ?? "")
                            .foregroundColor(.red)
                    } else {
                        Text(data.dateRun ?? "")
                    }
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
            .frame(minWidth: 850, minHeight: 500, alignment: .center)

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
        return Allprofilesandtasks().alltasks?.sorted(by: { conf1, conf2 in
            if let date1 = conf1.dateRun, let date2 = conf2.dateRun {
                if date1.en_us_date_from_string() > date2.en_us_date_from_string() {
                    return true
                } else {
                    return false
                }
            }
            return false
        }) ?? []
    }
}

extension AlltasksView {
    func dismissview() {
        isPresented = false
    }

    func markconfig(_ config: Configuration?) -> Bool {
        if let dateRun = config?.dateRun {
            if let secondssince = config?.lastruninseconds {
                let dayssincelastbackup = String(format: "%.2f", secondssince / (60 * 60 * 24))
                if secondssince / (60 * 60 * 24) > SharedReference.shared.marknumberofdayssince {
                    return true
                }
            }
        }
        return false
    }
}
