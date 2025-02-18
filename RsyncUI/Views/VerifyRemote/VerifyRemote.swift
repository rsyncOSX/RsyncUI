//
//  VerifyRemote.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum VerifyDestinationView: String, Identifiable {
    case executepushpull
    var id: String { rawValue }
}

struct VerifyTasks: Hashable, Identifiable {
    let id = UUID()
    var task: VerifyDestinationView
}

struct VerifyRemote: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var verifynavigation: [VerifyTasks]
    // For supporting URL links
    @Binding var queryitem: URLQueryItem?

    @State private var selectedconfig: SynchronizeConfiguration?

    var body: some View {
        // NavigationStack(path: $verifynavigation) {
        if selectedconfig == nil {
            VStack {
                Text("**Warning:** This function is advisory only.")
                    .foregroundColor(.blue)
                    .font(.title)

                HStack {
                    Text("Select a task in Synchronize view and select the ")
                        .foregroundColor(.blue)
                        .font(.title)

                    Text(Image(systemName: "bolt.shield"))
                        .foregroundColor(.yellow)
                        .font(.title)

                    Text(" to verify.")
                        .foregroundColor(.blue)
                        .font(.title)
                }
            }
            .onChange(of: queryitem) {
                // URL code
                handlequeryitem()
            }
        } else if let selectedconfig {
            DetailsPushPullView(rsyncUIdata: rsyncUIdata,
                                verifynavigation: $verifynavigation,
                                queryitem: $queryitem,
                                config: selectedconfig)
        }
    }

    // URL code
    func handlequeryitem() {
        Logger.process.info("VerifyRemote: Change on queryitem discovered")
        // This is from URL
        let backupid = queryitem?.value
        if let config = rsyncUIdata.configurations?.first(where: { $0.backupID.replacingOccurrences(of: " ", with: "_") == backupid }),
           config.offsiteServer.isEmpty == false,
           SharedReference.shared.rsyncversion3,
           queryitem != nil
        {
            selectedconfig = config
            guard selectedconfig?.task != SharedReference.shared.halted else { return }
            // Set config and execute a Verify
            queryitem = nil
        }
    }

    func abort() {
        InterruptProcess()
    }

    var configurations: [SynchronizeConfiguration] {
        rsyncUIdata.configurations?.filter { configuration in
            configuration.offsiteServer.isEmpty == false &&
                configuration.task == SharedReference.shared.synchronize &&
                SharedReference.shared.rsyncversion3 == true
        } ?? []
    }
}
