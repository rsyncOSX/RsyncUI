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
        infoaboutoneconfig
    }

    var localizedrundate: String {
        if let daterun = config?.dateRun {
            guard daterun.isEmpty == false else { return "" }
            let usdate = daterun.en_us_date_from_string()
            return usdate.long_localized_string_from_date()
        }
        return NSLocalizedString("not executed", comment: "OneConfig")
    }

    @SpacedTextBuilder
    var infoaboutoneconfig: Text {
        if config?.backupID.isEmpty ?? true {
            Text(NSLocalizedString("Synchronizing ID", comment: "QuicktaskView") + ": ")
                .foregroundColor(Color.blue)
            Text("not set")
        } else {
            Text(NSLocalizedString("Synchronizing ID", comment: "QuicktaskView") + ": ")
                .foregroundColor(Color.blue)
            Text(config?.backupID ?? "")
        }
        Text(NSLocalizedString("Task", comment: "QuicktaskView") + ": ")
            .foregroundColor(Color.blue)
        Text(config?.task ?? "")
        Text(NSLocalizedString("Localcatalog", comment: "QuicktaskView") + ": ")
            .foregroundColor(Color.blue)
        Text(config?.localCatalog ?? "")
        Text(NSLocalizedString("Remotecatalog", comment: "QuicktaskView") + ": ")
            .foregroundColor(Color.blue)
        Text(config?.offsiteCatalog ?? "")
        if config?.offsiteServer.isEmpty ?? true {
            Text(NSLocalizedString("Remote server", comment: "QuicktaskView") + ": ")
                .foregroundColor(Color.blue)
            Text(NSLocalizedString("Localhost", comment: "QuicktaskView") + ": ")
        } else {
            Text(NSLocalizedString("Remote server", comment: "QuicktaskView") + ": ")
                .foregroundColor(Color.blue)
            Text(config?.offsiteServer ?? "")
        }
        Text(NSLocalizedString("Last rundate", comment: "QuicktaskView") + ": ")
            .foregroundColor(Color.blue)
        Text(localizedrundate)
    }
}
