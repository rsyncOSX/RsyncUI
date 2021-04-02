//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/04/2021.
//

import SwiftUI

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""

    // Executed labels
    @State private var executed = false

    var body: some View {
        Form {
            headingtitle

            HStack {
                // For center
                Spacer()

                // Column 1
                VStack(alignment: .leading) {
                    pickerselecttypeoftask

                    localandremotecatalog

                    remoteuserandserver
                }

                // For center
                Spacer()
            }

            VStack {
                Spacer()

                HStack {
                    // Present when either added, updated or profile created
                    if executed == true { notifyexecuted }
                }

                HStack {
                    Spacer()

                    Button(NSLocalizedString("Execute", comment: "QuicktaskView")) {}
                        .buttonStyle(PrimaryButtonStyle())

                    Button(NSLocalizedString("View", comment: "QuicktaskView")) {}
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .lineSpacing(2)
        .padding()
    }

    // Add and edit text values
    var setlocalcatalog: some View {
        EditValue(250, NSLocalizedString("Add localcatalog - required", comment: "QuicktaskView"), $localcatalog)
    }

    var setremotecatalog: some View {
        EditValue(250, NSLocalizedString("Add remotecatalog - required", comment: "QuicktaskView"), $remotecatalog)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text(NSLocalizedString("Catalog parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(250, NSLocalizedString("Add source catalog", comment: "QuicktaskView"), $localcatalog)

            // remotecatalog
            EditValue(250, NSLocalizedString("Add destination catalog", comment: "QuicktaskView"), $remotecatalog)
        }
    }

    var setremoteuser: some View {
        EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
    }

    var setremoteserver: some View {
        EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
            // Remote server
            EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "AddConfigurationsView") + ":",
               selection: $selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    var notifyexecuted: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Executed", comment: "QuicktaskView"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var headingtitle: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Quick task", comment: "QuicktaskView"))
                .modifier(Tagheading(.title2, .leading))
                .foregroundColor(Color.blue)
        }
    }
}

extension QuicktaskView {
    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
    }
}
