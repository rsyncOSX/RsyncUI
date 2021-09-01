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
                /*
                 if rsyncUIdata.hasactiveschedules(config.hiddenID) {
                     Text(task)
                         .modifier(FixedTag(60, .leading))
                         .foregroundColor(Color.accentColor)
                 } else {
                     Text(task)
                         .modifier(FixedTag(60, .leading))
                 }
                  */
                Text(task)
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

    var task: String {
        if (config.executepretask ?? 0) == 1 {
            return "* " + config.task
        } else {
            return config.task
        }
    }
}
