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
        return "not executed"
    }

    @SpacedTextBuilder
    var infoaboutoneconfig: Text {
        Text("Task" + ": ")
            .foregroundColor(Color.blue)
        Text(config?.task ?? "")
        if config?.backupID.isEmpty ?? true {
            Text("Synchronize ID" + ": ")
                .foregroundColor(Color.blue)
            Text("not set")
        } else {
            Text("Synchronize ID" + ": ")
                .foregroundColor(Color.blue)
            Text(config?.backupID ?? "")
        }
        Text("Localcatalog" + ": ")
            .foregroundColor(Color.blue)
        Text(config?.localCatalog ?? "")
        Text("Remotecatalog" + ": ")
            .foregroundColor(Color.blue)
        Text(config?.offsiteCatalog ?? "")
        if config?.offsiteServer.isEmpty ?? true {
            Text("Remote server" + ": ")
                .foregroundColor(Color.blue)
            Text("Localhost" + ": ")
        } else {
            Text("Remote server" + ": ")
                .foregroundColor(Color.blue)
            Text(config?.offsiteServer ?? "")
        }
        Text("Last rundate" + ": ")
            .foregroundColor(Color.blue)
        Text(localizedrundate)
    }
}
