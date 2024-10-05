//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//

import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var donotaddtrailingslash: Bool = false
    @State private var dryrun: Bool = true

    // Executed labels
    @State private var showprogressview = false
    @State private var rsyncoutput: ObservableRsyncOutput?
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    @State private var focusstartexecution: Bool = false
    // Completed task
    @State private var completed: Bool = false
    // Update pressed
    @State var updated: Bool = false

    var choosecatalog = true

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState private var focusField: QuicktaskField?

    var body: some View {
        ZStack {
            Spacer()

            // Column 1
            VStack(alignment: .leading) {
                HStack {
                    pickerselecttypeoftask

                    VStack(alignment: .trailing) {
                        Toggle("--dry-run", isOn: $dryrun)
                            .toggleStyle(.switch)

                        Toggle("Don´t add /", isOn: $donotaddtrailingslash)
                            .toggleStyle(.switch)
                    }
                    .padding()
                }

                VStack(alignment: .leading) {
                    if selectedrsynccommand == .synchronize {
                        localandremotecatalog
                    } else {
                        localandremotecatalogsyncremote
                    }

                    remoteuserandserver
                }
            }

            if showprogressview { ProgressView() }
            if focusaborttask { labelaborttask }
            if focusstartexecution { labelstartexecution }
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                focusField = nil
                dryrun = true
            default:
                return
            }
        }
        .onAppear {
            focusField = .localcatalogField
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    getconfigandexecute()
                } label: {
                    if updated == false {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color(.blue))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.blue))
                    }
                }
                .help("Synchronize (⌘R)")
            }

            ToolbarItem {
                Button {
                    abort()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
        .padding()
        .navigationDestination(isPresented: $completed) {
            OutputRsyncView(output: rsyncoutput?.output ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                getconfigandexecute()
            })
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "") + ":",
               selection: $selectedrsynccommand)
        {
            ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
        .onChange(of: selectedrsynccommand) {
            resetform()
        }
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            HStack {
                EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $localcatalog, choosecatalog: choosecatalog)
            }

            // remotecatalog
            HStack {
                EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            HStack {
                EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $localcatalog, choosecatalog: choosecatalog)
            }

            // remotecatalog
            HStack {
                EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, NSLocalizedString("Add remote user", comment: ""), $remoteuser)
                .focused($focusField, equals: .remoteuserField)
                .textContentType(.none)
                .submitLabel(.continue)
            // Remote server
            EditValue(300, NSLocalizedString("Add remote server", comment: ""), $remoteserver)
                .focused($focusField, equals: .remoteserverField)
                .textContentType(.none)
                .submitLabel(.return)
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

    func getconfigandexecute() {
        updated = true
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 donotaddtrailingslash,
                                 remoteuser,
                                 remoteserver,
                                 "")
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            execute(config: newconfig, dryrun: dryrun)
        }
    }

    func execute(config: SynchronizeConfiguration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        rsyncoutput = ObservableRsyncOutput()
        // Start progressview
        showprogressview = true
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func abort() {
        _ = InterruptProcess()
    }

    func processtermination(_ stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(stringoutputfromrsync)
        completed = true
        updated = false
    }
}
