//
//  SidebarMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import OSLog
import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, rsync_parameters, snapshots, log_listings, restore, profiles, verify_remote
    var id: String { rawValue }
}

struct SidebarMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?
    @Bindable var errorhandling: AlertError

    @State private var estimateprogressdetails = EstimateProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedview: Sidebaritems = .synchronize
    // Navigation rsyncparameters
    @State var rsyncnavigation: [ParametersTasks] = []
    // Navigation executetasks
    @State var executetasknavigation: [Tasks] = []
    // Navigation addtasks and verify
    // Needed here because if not empty sidebar is disabled
    @State private var addtasknavigation: [AddTasks] = []
    @State var verifynavigation: [VerifyTasks] = []
    // Check if new version
    @State private var newversion = CheckfornewversionofRsyncUI()

    var body: some View {
        NavigationSplitView {
            profilepicker
                .padding([.bottom, .top], 5)
                .disabled(disablesidebarmeny)

            Divider()

            List(Sidebaritems.allCases, selection: $selectedview) { selectedview in
                NavigationLink(value: selectedview) {
                    SidebarRow(sidebaritem: selectedview)
                }

                if selectedview == .tasks || selectedview == .snapshots || selectedview == .restore { Divider() }
            }
            .listStyle(.sidebar)
            .disabled(disablesidebarmeny)

            if newversion.notifynewversion {
                MessageView(mytext: "There is a new version\navailable for download", size: .caption2)
            }

            MessageView(mytext: SharedReference.shared.rsyncversionshort ?? "", size: .caption2)

        } detail: {
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
            if let error = errorhandling.activeError {
                Alert(localizedError: error)
            } else {
                Alert(title: Text("No error"))
            }
        })
        .onAppear {
            Task {
                newversion.notifynewversion = await Getversionofrsync().getversionsofrsyncui()
                SharedReference.shared.newversion = newversion.notifynewversion
            }
        }
        .onOpenURL { incomingURL in
            Logger.process.info("App was opened via URL: \(incomingURL)")
            handleIncomingURL(incomingURL)
        }
    }

    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selectedprofile: $selectedprofile, addtasknavigation: $addtasknavigation)
        case .log_listings:
            if rsyncUIdata.configurations != nil {
                LogsbyConfigurationView(rsyncUIdata: rsyncUIdata)
            } else {
                DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("No log records yet.", comment: ""))
            }
        case .rsync_parameters:
            RsyncParametersView(rsyncUIdata: rsyncUIdata, rsyncnavigation: $rsyncnavigation)
        case .restore:
            if let configurations = rsyncUIdata.configurations {
                NavigationStack {
                    RestoreTableView(profile: $rsyncUIdata.profile,
                                     configurations: configurations)
                }
            } else {
                DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("No configurations yet.", comment: ""))
            }
        case .snapshots:
            SnapshotsView(rsyncUIdata: rsyncUIdata)
        case .synchronize:
            SidebarTasksView(rsyncUIdata: rsyncUIdata,
                             selecteduuids: $selecteduuids,
                             estimateprogressdetails: estimateprogressdetails,
                             executetasknavigation: $executetasknavigation)
        case .profiles:
            ProfileView(rsyncUIdata: rsyncUIdata, profilenames: profilenames, selectedprofile: $selectedprofile)
        case .verify_remote:
            NavigationStack {
                VerifyRemote(rsyncUIdata: rsyncUIdata, verifynavigation: $verifynavigation)
            }
        }
    }

    // Handles the incoming URL and performs validations before acknowledging.
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "rsyncuiapp" else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logger.process.warning("Invalid URL")
            return
        }
        print(components)

        // selectedview = .profiles

        // openedRecipeName = recipeName
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile) {
                ForEach(profilenames.profiles ?? [], id: \.self) { profile in
                    Text(profile.profile ?? "")
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
            .onChange(of: selectedprofile) {
                selecteduuids.removeAll()
            }
            Spacer()
        }
    }

    var profilenames: Profilenames {
        Profilenames()
    }

    var disablesidebarmeny: Bool {
        rsyncnavigation.isEmpty == false ||
            executetasknavigation.isEmpty == false ||
            addtasknavigation.isEmpty == false ||
            verifynavigation.isEmpty == false ||
            SharedReference.shared.process != nil
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            "text.badge.plus"
        case .log_listings:
            "text.alignleft"
        case .rsync_parameters:
            "command.circle.fill"
        case .restore:
            "arrowshape.turn.up.forward"
        case .snapshots:
            "text.badge.plus"
        case .synchronize:
            "arrowshape.turn.up.backward"
        case .profiles:
            "arrow.triangle.branch"
        case .verify_remote:
            "arrow.down.circle.fill"
        }
    }
}
