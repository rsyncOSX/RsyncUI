//
//  NavigationAlltasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/11/2023.
//

import Foundation
import SwiftUI

@available(macOS 14.0, *)
struct NavigationAlltasksView: View {
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
                TableColumn("Days") { data in
                    if markconfig(data) {
                        Text(data.dayssincelastbackup ?? "")
                            .foregroundColor(.red)
                    } else {
                        Text(data.dayssincelastbackup ?? "")
                    }
                }
                .width(max: 50)
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
        }
        .padding()
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

@available(macOS 14.0, *)
extension NavigationAlltasksView {
    func markconfig(_ config: Configuration?) -> Bool {
        if config?.dateRun != nil {
            if let secondssince = config?.lastruninseconds {
                if secondssince / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince) {
                    return true
                }
            }
        }
        return false
    }
}
