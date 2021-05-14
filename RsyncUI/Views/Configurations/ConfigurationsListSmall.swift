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
        VStack {
            configlist
        }
    }

    var configlist: some View {
        List(selection: $selectedconfig) {
            ForEach(configurationssorted) { configurations in
                OneConfigSmall(config: configurations)
                    .tag(configurations)
            }
            .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
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
}
