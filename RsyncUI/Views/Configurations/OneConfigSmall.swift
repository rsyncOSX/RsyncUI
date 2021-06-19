//
//  OneConfigSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//

import SwiftUI

struct OneConfigSmall: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata

    var config: Configuration

    var body: some View {
        forall
    }

    var forall: some View {
        HStack {
            Group {
                if config.backupID.isEmpty {
                    Text("Synchronize ID")
                        .modifier(FixedTag(100, .leading))
                } else {
                    Text(config.backupID)
                        .modifier(FixedTag(100, .leading))
                }
                Text(config.task)
                    .modifier(FixedTag(60, .leading))
                Text(config.localCatalog)
                    .modifier(FlexTag(180, .leading))
                Text(config.offsiteCatalog)
                    .modifier(FlexTag(180, .leading))
            }

            if config.offsiteServer.isEmpty {
                Text("localhost")
                    .modifier(FixedTag(60, .leading))
            } else {
                Text(config.offsiteServer)
                    .modifier(FixedTag(60, .leading))
            }
        }
    }
}
