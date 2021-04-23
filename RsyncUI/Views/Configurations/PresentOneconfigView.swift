//
//  PresentOneconfigView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/04/2021.
//

import SwiftUI

struct PresentOneconfigView: View {
    @Binding var config: Configuration?

    var body: some View {
        presentoneconfig
    }

    var presentoneconfig: some View {
        HStack {
            Group {
                if config?.backupID.isEmpty ?? true {
                    Text("Synchronizing ID")
                        .modifier(FixedTag(150, .leading))
                } else {
                    Text(config?.backupID ?? "")
                        .modifier(FixedTag(150, .leading))
                }
                Text(config?.task ?? "")
                    .modifier(FixedTag(80, .leading))
                Text(config?.localCatalog ?? "")
                    .modifier(FlexTag(180, .leading))
                Text(config?.offsiteCatalog ?? "")
                    .modifier(FlexTag(180, .leading))
            }

            Group {
                if config?.offsiteServer.isEmpty ?? true {
                    Text("localhost")
                        .modifier(FixedTag(80, .leading))
                } else {
                    Text(config?.offsiteServer ?? "")
                        .modifier(FixedTag(100, .leading))
                }
                if config?.offsiteUsername.isEmpty ?? true {
                    Text("no username")
                        .modifier(FixedTag(60, .leading))
                } else {
                    Text(config?.offsiteUsername ?? "")
                        .modifier(FixedTag(60, .leading))
                }

                Text(localizedrundate)
            }
        }
    }

    var localizedrundate: String {
        if let daterun = config?.dateRun {
            guard daterun.isEmpty == false else { return "" }
            let usdate = daterun.en_us_date_from_string()
            return usdate.long_localized_string_from_date()
        }
        return NSLocalizedString("not executed", comment: "OneConfig")
    }
}
