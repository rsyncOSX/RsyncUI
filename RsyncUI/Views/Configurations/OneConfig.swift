//
//  OneConfig.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import SwiftUI

struct OneConfig: View {
    @Binding var forestimated: Bool
    var config: Configuration

    var body: some View {
        if forestimated {
            Spacer()

            forall

            Spacer()
        } else {
            HStack {
                Spacer()

                forall
                noestimation

                Spacer()
            }
        }
    }

    var forall: some View {
        HStack {
            Group {
                Text("")
                    .modifier(FixedTag(20, .leading))
                Text("")
                    .modifier(FixedTag(20, .leading))
                if config.backupID.isEmpty {
                    Text("Synchronizing ID")
                        .modifier(FixedTag(120, .leading))
                } else {
                    Text(config.backupID)
                        .modifier(FixedTag(120, .leading))
                }
                Text(config.task)
                    .modifier(FixedTag(80, .leading))
                Text(config.localCatalog)
                    .modifier(FlexTag(180, .leading))
                Text(config.offsiteCatalog)
                    .modifier(FlexTag(180, .leading))
            }

            Group {
                if config.offsiteServer.isEmpty {
                    Text("localhost")
                        .modifier(FixedTag(80, .leading))
                } else {
                    Text(config.offsiteServer)
                        .modifier(FixedTag(100, .leading))
                }
                if config.offsiteUsername.isEmpty {
                    Text("no username")
                        .modifier(FixedTag(60, .leading))
                } else {
                    Text(config.offsiteUsername)
                        .modifier(FixedTag(60, .leading))
                }
            }
        }
    }

    var noestimation: some View {
        HStack(alignment: .center) {
            if Double(config.dayssincelastbackup ?? "0") ?? 0 > SharedReference.shared.marknumberofdayssince {
                Text(config.dayssincelastbackup ?? "")
                    .modifier(FixedTag(35, .trailing))
                    .foregroundColor(Color.red)
            } else {
                Text(config.dayssincelastbackup ?? "")
                    .modifier(FixedTag(35, .trailing))
            }
            Text(config.dateRun ?? "not executed")
                .modifier(FixedTag(120, .leading))
        }
    }
}
