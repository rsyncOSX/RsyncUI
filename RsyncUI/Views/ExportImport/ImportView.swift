//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ImportView: View {
    @Binding var focusimport: Bool
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var filenameimport: String = ""
    @State private var configurations = [SynchronizeConfiguration]()

    var body: some View {
        VStack {
            if configurations.isEmpty == false {
                ListofTasksLightView(selecteduuids: $selecteduuids, profile: nil, configurations: configurations)
            } else {
                Text("Select a file for import")
            }

            Spacer()

            HStack {
                if filenameimport.isEmpty == false {
                    Text(filenameimport)
                }

                OpencatalogView(catalog: $filenameimport, choosecatalog: false)

                // Reset hiddenID if import
                Button {
                    guard filenameimport.isEmpty == false else { return }
                    if let importconfigurations = ReadImportConfigurationsJSON(filenameimport).importconfigurations {
                        configurations = importconfigurations
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(Color(.blue))
                }
                .help("Import tasks")

                Button {
                    focusimport = false
                } label: {
                    Image(systemName: "clear")
                        .foregroundColor(Color(.blue))
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}
