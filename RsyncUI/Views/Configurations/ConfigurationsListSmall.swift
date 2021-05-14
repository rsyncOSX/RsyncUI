//
//  ConfigurationsListSmall.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/05/2021.
//

import SwiftUI

struct ConfigurationsListSmall: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var selectedconfig: Configuration?

    @State private var forestimated = false

    var body: some View {
        configlist
    }

    var configlist: some View {
        Section(header: header) {
            List(selection: $selectedconfig) {
                ForEach(configurationssorted) { configurations in
                    OneConfig(forestimated: $forestimated,
                              config: configurations)
                        .tag(configurations)
                }
                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
        }
    }

    var configurationssorted: [Configuration] {
        if let configurations = rsyncUIData.configurations {
            let sorted = configurations.sorted { conf1, conf2 in
                if let days1 = conf1.dateRun?.en_us_date_from_string(),
                   let days2 = conf2.dateRun?.en_us_date_from_string()
                {
                    if days1 > days2 {
                        return true
                    } else {
                        return false
                    }
                }
                return false
            }
            return sorted
        }
        return []
    }

    var header: some View {
        HStack {
            Text(NSLocalizedString("Synchronize ID", comment: "ConfigurationsList"))
                .modifier(FixedTag(120, .center))
            Text(NSLocalizedString("Task", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .center))
            Text(NSLocalizedString("Local catalog", comment: "ConfigurationsList"))
                .modifier(FixedTag(180, .center))
            Text(NSLocalizedString("Remote catalog", comment: "ConfigurationsList"))
                .modifier(FixedTag(180, .center))
            Text(NSLocalizedString("Server", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .center))
            Text(NSLocalizedString("User", comment: "ConfigurationsList"))
                .modifier(FixedTag(35, .center))
            Text(NSLocalizedString("Days", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .trailing))
            Text(NSLocalizedString("Last", comment: "ConfigurationsList"))
                .modifier(FixedTag(80, .trailing))
        }
    }
}
