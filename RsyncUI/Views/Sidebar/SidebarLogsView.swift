//
//  LogsGroup.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 04/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct SidebarLogsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @State private var selectedconfig: Configuration?

    var body: some View {
        VStack {
            headingtitle

            ConfigurationLogsView(selectedconfig: $selectedconfig.onChange { rsyncOSXData.update() })
        }
        .padding()
    }

    var headingtitle: some View {
        HStack {
            VStack {
                Text(NSLocalizedString("List logs", comment: "SidebarLogsView"))
                    .modifier(Tagheading(.title2, .leading))
                    .foregroundColor(Color.blue)
            }

            Spacer()
        }
        .padding()
    }
}
