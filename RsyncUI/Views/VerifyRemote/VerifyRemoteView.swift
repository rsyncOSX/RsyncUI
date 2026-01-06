//
//  VerifyRemoteView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

enum DestinationVerifyView: Hashable {
    case pushpullview(configID: SynchronizeConfiguration.ID)
    case executenpushpullview(configID: SynchronizeConfiguration.ID)
}

struct Verify: Hashable, Identifiable {
    let id = UUID()
    var task: DestinationVerifyView
}

struct VerifyRemoteView: View {
    @State private var configurationsdata = RsyncUIconfigurations()

    @State private var selectedprofileID: ProfilesnamesRecord.ID?
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedconfig: SynchronizeConfiguration?
    // Selected task is halted
    @State private var selectedtaskishalted: Bool = false
    // Adjusted output rsync
    @State private var isadjusted: Bool = false
    // Decide push or pull
    @State private var pushorpull = ObservableVerifyRemotePushPull()
    @State private var pushpullcommand = PushPullCommand.pushLocal
    @State private var verifypath: [Verify] = []
    // Show Inspector view
    @State var showinspector: Bool = false

    var body: some View {
        NavigationSplitView {
            // Only show profile picker if there are other profiles
            // Id default only, do not show profile picker

            Picker("", selection: $selectedprofileID) {
                Text("Default")
                    .tag(nil as ProfilesnamesRecord.ID?)
                ForEach(configurationsdata.validprofilesverifytasks, id: \.self) { profile in
                    Text(profile.profilename)
                        .tag(profile.id)
                }
            }
            .frame(width: 180)
            .padding([.bottom, .top, .trailing], 7)

        } detail: {
            NavigationStack(path: $verifypath) {
                ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                            configurations: configurationsdata.configurations)
                    .onChange(of: selecteduuids) {
                        if let configurations = configurationsdata.configurations {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                guard selectedconfig?.task != SharedReference.shared.halted else { return }
                                selectedconfig = configurations[index]
                                showinspector = true
                            } else {
                                selectedconfig = nil
                                showinspector = false
                            }
                        }
                    }
            }.navigationDestination(for: Verify.self) { which in
                makeView(view: which.task)
            }
        }
        .inspector(isPresented: $showinspector) {
            inspectorView
                .inspectorColumnWidth(min: 100, ideal: 200, max: 300)
        }
        .task {
            let catalognames = Homepath().getFullPathMacSerialCatalogsAsStringNames()
            configurationsdata.validprofilesverifytasks = catalognames.map { catalog in
                ProfilesnamesRecord(catalog)
            }
        }
        .task(id: selectedprofileID) {
            selecteduuids.removeAll()
            selectedconfig = nil
            let profile: String? = if let index = configurationsdata
                .validprofilesverifytasks
                .firstIndex(where: { $0.id == selectedprofileID }) {
                configurationsdata.validprofilesverifytasks[index].profilename
            } else {
                nil
            }
            configurationsdata.configurations = await ActorReadSynchronizeConfigurationJSON()
                .readjsonfilesynchronizeconfigurations(profile,
                                                       SharedReference.shared.rsyncversion3)
        }
    }

    var inspectorView: some View {
        VStack(alignment: .center) {
            if selecteduuids.count == 1, selectedconfig != nil {
                ConditionalGlassButton(
                    systemImage: "arrow.up",
                    helpText: "Verify selected"
                ) {
                    guard let selectedconfig else { return }
                    guard selectedtaskishalted == false else { return }
                    guard SharedReference.shared.process == nil else { return }
                    showinspector = false
                    verifypath.append(Verify(task: .pushpullview(configID: selectedconfig.id)))
                }
                .padding(10)
            }

            Toggle("Adjust output", isOn: $isadjusted)
                .toggleStyle(.switch)
                .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    @MainActor @ViewBuilder
    func makeView(view: DestinationVerifyView) -> some View {
        switch view {
        case let .executenpushpullview(configuuid):
            if let index = configurationsdata.configurations?.firstIndex(where: { $0.id == configuuid }) {
                if let config = configurationsdata.configurations?[index] {
                    ExecutePushPullView(pushorpull: $pushorpull,
                                        pushpullcommand: $pushpullcommand,
                                        config: config)
                }
            }
        case let .pushpullview(configuuid):
            if let index = configurationsdata.configurations?.firstIndex(where: { $0.id == configuuid }) {
                if let config = configurationsdata.configurations?[index] {
                    PushPullView(pushorpull: $pushorpull,
                                 verifypath: $verifypath,
                                 pushpullcommand: $pushpullcommand,
                                 config: config,
                                 isadjusted: isadjusted)
                }
            }
        }
    }
}
