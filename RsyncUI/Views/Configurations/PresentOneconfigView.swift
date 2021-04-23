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
        VStack(alignment: .leading) {
            HStack {
                if config?.backupID.isEmpty ?? true {
                    Text("Id: ")
                        .foregroundColor(Color.blue)
                    Text("Synchronizing ID")
                } else {
                    Text("Id: ")
                        .foregroundColor(Color.blue)
                    Text(config?.backupID ?? "")
                }
                Text("task: ")
                    .foregroundColor(Color.blue)
                Text(config?.task ?? "")
            }

            HStack {
                Text("localcatalog: ")
                    .foregroundColor(Color.blue)
                Text(config?.localCatalog ?? "")

                Text("remotecatalog: ")
                    .foregroundColor(Color.blue)
                Text(config?.offsiteCatalog ?? "")
            }

            HStack {
                if config?.offsiteServer.isEmpty ?? true {
                    Text("remote: ")
                        .foregroundColor(Color.blue)
                    Text("localhost")
                } else {
                    Text("remote :")
                        .foregroundColor(Color.blue)
                    Text(config?.offsiteServer ?? "")
                }
                Text("last rundate: ")
                    .foregroundColor(Color.blue)
                Text(localizedrundate)
            }
        }
        .border(Color.gray)
        .padding(5)
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
