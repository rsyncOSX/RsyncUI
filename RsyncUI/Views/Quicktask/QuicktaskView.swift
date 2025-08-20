//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//

import OSLog
import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote
    case not_selected

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase.replacingOccurrences(of: "_", with: " ") }
}

enum ValidateInputQuicktask: LocalizedError {
    case localcatalog
    case remotecatalog
    case offsiteusername
    case offsiteserver

    var errorDescription: String? {
        switch self {
        case .localcatalog:
            "Source folder cannot be empty"
        case .offsiteusername:
            "Username cannot be empty"
        case .remotecatalog:
            "Destination folder cannot be empty"
        case .offsiteserver:
            "Servername cannot be empty"
        }
    }
}

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var trailingslashoptions: TrailingSlash = .add
    @State private var dryrun: Bool = true
    @State private var catalogorfile: Bool = true

    @AppStorage("quicklocalcatalog") var quicklocalcatalog: String = ""
    @AppStorage("quickremotecatalog") var quickremotecatalog: String = ""
    @AppStorage("quickselectedrsynccommand") var quickselectedrsynccommand: String = ""

    @AppStorage("quickremoteuser") var quickremoteuser: String = ""
    @AppStorage("quickremoteserver") var quickremoteserver: String = ""

    @AppStorage("quicktrailingslashoptions") var quicktrailingslashoptions: String = ""
    @AppStorage("quickcatalogorfile") var quickcatalogorfile: Bool = true

    // Executed labels
    @State private var showprogressview = false
    @State private var rsyncoutput = ObservableRsyncOutput()
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    @State private var focusstartexecution: Bool = false
    // Completed task
    @State private var completed: Bool = false

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState private var focusField: QuicktaskField?

    @State private var selectedhomecatalog: Catalognames.ID?
    @State private var selectedAttachedVolume: AttachedVolumes.ID?
    @State private var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalognames]
    let attachedVolumes: [AttachedVolumes]

    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Parameters to Task")
                    .font(.title3)
                    .fontWeight(.bold))
                {
                    Picker(NSLocalizedString("Action", comment: ""),
                           selection: $selectedrsynccommand)
                    {
                        ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                            .tag($0)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(width: 180)
                    .onChange(of: selectedrsynccommand) {
                        UserDefaults.standard.set(selectedrsynccommand.rawValue, forKey: "quickselectedrsynccommand")
                        Task {
                            // Sleep for a second, then clear catalog valuse
                            try await Task.sleep(seconds: 1)
                            localcatalog = ""
                            remotecatalog = ""
                            selectedhomecatalog = nil
                        }
                    }
                    .onAppear {
                        if let selectedrsynccommand = UserDefaults.standard.value(forKey: "quickselectedrsynccommand") {
                            Logger.process.info("QuicktaskView: set default settings for selectedrsynccommand: \(selectedrsynccommand as! NSObject)")

                            switch selectedrsynccommand as! String {
                            case "synchronize":
                                self.selectedrsynccommand = TypeofTaskQuictask.synchronize
                            case "syncremote":
                                self.selectedrsynccommand = TypeofTaskQuictask.syncremote
                            case "not_selected":
                                self.selectedrsynccommand = TypeofTaskQuictask.not_selected
                            default:
                                self.selectedrsynccommand = TypeofTaskQuictask.synchronize
                            }
                        }
                    }

                    VStack {
                        Toggle("--dry-run", isOn: $dryrun)
                            .toggleStyle(.switch)
                            .onTapGesture {
                                withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                    dryrun.toggle()
                                }
                            }

                        Toggle("File(off) or Folder(on)", isOn: $catalogorfile)
                            .toggleStyle(.switch)
                            .onChange(of: catalogorfile) {
                                if catalogorfile {
                                    trailingslashoptions = .do_not_add
                                } else {
                                    trailingslashoptions = .add
                                }
                            }
                            .onTapGesture {
                                withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                    catalogorfile.toggle()
                                }
                            }
                            .onChange(of: catalogorfile) {
                                UserDefaults.standard.set(catalogorfile, forKey: "quickcatalogorfile")
                            }
                            .onAppear {
                                if let quickcatalogorfile = UserDefaults.standard.value(forKey: "quickcatalogorfile") {
                                    catalogorfile = quickcatalogorfile as! Bool
                                }
                            }
                    }

                    Picker(NSLocalizedString("Trailing /", comment: ""),
                           selection: $trailingslashoptions)
                    {
                        ForEach(TrailingSlash.allCases) { Text($0.description)
                            .tag($0)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    .frame(width: 180)
                    .onChange(of: trailingslashoptions) {
                        UserDefaults.standard.set(trailingslashoptions.rawValue, forKey: "quicktrailingslash")
                    }
                    .onAppear {
                        if let trailingslashoptions = UserDefaults.standard.value(forKey: "quicktrailingslash") {
                            Logger.process.info("QuicktaskView: set default settings for trailingslashoptions: \(trailingslashoptions as! NSObject)")

                            switch trailingslashoptions as! String {
                            case "do_not_check":
                                self.trailingslashoptions = TrailingSlash.do_not_check
                            case "do_not_add":
                                self.trailingslashoptions = TrailingSlash.do_not_add
                            case "add":
                                self.trailingslashoptions = TrailingSlash.add
                            default:
                                self.trailingslashoptions = TrailingSlash.add
                            }
                        }
                    }
                }
                if selectedrsynccommand == .synchronize || selectedrsynccommand == .not_selected {
                    Section(header: Text("Source and destination")
                        .font(.title3)
                        .fontWeight(.bold))
                    {
                        HStack {
                            EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""), $localcatalog)
                                .focused($focusField, equals: .localcatalogField)
                                .textContentType(.none)
                                .submitLabel(.continue)
                                .onChange(of: localcatalog) {
                                    UserDefaults.standard.set(localcatalog, forKey: "quicklocalcatalog")
                                }
                                .onAppear {
                                    if let quicklocalcatalog = UserDefaults.standard.value(forKey: "quicklocalcatalog") {
                                        Logger.process.info("QuicktaskView: set default settings for localcatalog: \(quicklocalcatalog as! NSObject)")
                                        localcatalog = quicklocalcatalog as! String
                                    }
                                }

                            Picker("", selection: $selectedhomecatalog) {
                                Text("Home Catalogs (source)")
                                    .tag(nil as Catalognames.ID?)
                                ForEach(homecatalogs, id: \.self) { catalog in
                                    Text(catalog.catalogname)
                                        .tag(catalog.id)
                                }
                            }
                            .frame(width: 300)
                            .onChange(of: selectedhomecatalog) {
                                if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                                    localcatalog = localhome.appending("/") + homecatalogs[index].catalogname
                                }
                            }
                        }

                        // remotecatalog
                        HStack {
                            EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""), $remotecatalog)
                                .focused($focusField, equals: .remotecatalogField)
                                .textContentType(.none)
                                .submitLabel(.continue)
                                .onChange(of: remotecatalog) {
                                    UserDefaults.standard.set(remotecatalog, forKey: "quickremotecatalog")
                                }
                                .onAppear {
                                    if let quickremotecatalog = UserDefaults.standard.value(forKey: "quickremotecatalog") {
                                        Logger.process.info("QuicktaskView: set default settings for remotecatalog: \(quickremotecatalog as! NSObject)")

                                        remotecatalog = quickremotecatalog as! String
                                    }
                                }
                        }
                    }
                } else {
                    Section(header: Text("Source and destination")
                        .font(.title3)
                        .fontWeight(.bold))
                    {
                        // remotecatalog
                        HStack {
                            EditValueScheme(300, NSLocalizedString("Add Destination folder - required", comment: ""), $remotecatalog)
                                .focused($focusField, equals: .remotecatalogField)
                                .textContentType(.none)
                                .submitLabel(.continue)
                                .onChange(of: remotecatalog) {
                                    UserDefaults.standard.set(remotecatalog, forKey: "quickremotecatalog")
                                }
                                .onAppear {
                                    if let quickremotecatalog = UserDefaults.standard.value(forKey: "quickremotecatalog") {
                                        Logger.process.info("QuicktaskView: set default settings for remotecatalog: \(quickremotecatalog as! NSObject)")
                                        remotecatalog = quickremotecatalog as! String
                                    }
                                }
                            
                            Picker("", selection: $selectedhomecatalog) {
                                Text("Home Catalogs (destination)")
                                    .tag(nil as Catalognames.ID?)
                                ForEach(homecatalogs, id: \.self) { catalog in
                                    Text(catalog.catalogname)
                                        .tag(catalog.id)
                                }
                            }
                            .frame(width: 300)
                            .onChange(of: selectedhomecatalog) {
                                if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                                    remotecatalog = localhome.appending("/") + homecatalogs[index].catalogname
                                }
                            }
                        }

                        // localcatalog
                        HStack {
                            EditValueScheme(300, NSLocalizedString("Add Source folder - required", comment: ""), $localcatalog)
                                .focused($focusField, equals: .localcatalogField)
                                .textContentType(.none)
                                .submitLabel(.continue)
                                .onChange(of: localcatalog) {
                                    UserDefaults.standard.set(localcatalog, forKey: "quicklocalcatalog")
                                }
                                .onAppear {
                                    if let quicklocalcatalog = UserDefaults.standard.value(forKey: "quicklocalcatalog") {
                                        Logger.process.info("QuicktaskView: set default settings for localcatalog: \(quicklocalcatalog as! NSObject)")
                                        localcatalog = quicklocalcatalog as! String
                                    }
                                }
                        }
                    }
                }

                Section(header: Text("Remote user and server")
                    .font(.title3)
                    .fontWeight(.bold))
                {
                    // Remote user
                    EditValueScheme(300, NSLocalizedString("Add remote user - required", comment: ""), $remoteuser)
                        .focused($focusField, equals: .remoteuserField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onChange(of: remoteuser) { _, _ in
                            UserDefaults.standard.set(remoteuser, forKey: "quickremoteuser")
                        }
                        .onAppear {
                            if let quickremoteuser = UserDefaults.standard.string(forKey: "quickremoteuser") {
                                remoteuser = quickremoteuser
                            }
                        }
                    // Remote server
                    EditValueScheme(300, NSLocalizedString("Add remote server - required", comment: ""), $remoteserver)
                        .focused($focusField, equals: .remoteserverField)
                        .textContentType(.none)
                        .submitLabel(.return)
                        .onChange(of: remoteserver) {
                            UserDefaults.standard.set(remoteserver, forKey: "quickremoteserver")
                        }
                        .onAppear {
                            if let quickremoteserver = UserDefaults.standard.string(forKey: "quickremoteserver") {
                                remoteserver = quickremoteserver
                            }
                        }
                }
            }
            .formStyle(.grouped)

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
                    resetform()
                } label: {
                    if localcatalog.isEmpty == false {
                        Image(systemName: "clear")
                            .foregroundColor(Color(.red))
                    } else {
                        Image(systemName: "clear")
                    }
                }
                .help("Clear saved quicktask")
            }

            ToolbarItem {
                Button {
                    getconfigandexecute()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Synchronize (⌘R)")
                .disabled(selectedrsynccommand == .not_selected)
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
        .navigationTitle("Quicktask - only for remote server")
        .navigationDestination(isPresented: $completed) {
            OutputRsyncView(output: rsyncoutput.output ?? [])
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

    var attachedVolumesCatalogs: [String] {
        if let index = attachedVolumes.firstIndex(where: { $0.id == selectedAttachedVolume }) {
            let fm = FileManager.default
            let atpathURL = attachedVolumes[index].volumename
            var catalogs = [String]()
            do {
                for filesandfolders in try
                    fm.contentsOfDirectory(at: atpathURL, includingPropertiesForKeys: nil)
                    where filesandfolders.hasDirectoryPath
                {
                    catalogs.append(filesandfolders.lastPathComponent)
                }
                return catalogs
            } catch {
                return []
            }
        }
        return []
    }

    var localhome: String {
        Homepath().userHomeDirectoryPath ?? ""
    }
}

extension QuicktaskView {
    func resetform() {
        selectedrsynccommand = .synchronize
        trailingslashoptions = .add
        dryrun = true
        catalogorfile = true
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
        selectedhomecatalog = nil
        selectedAttachedVolume = nil
        selectedAttachedVolumeCatalogs = nil
    }

    func getconfigandexecute() {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 trailingslashoptions,
                                 remoteuser,
                                 remoteserver,
                                 "")

        guard selectedrsynccommand != .not_selected else { return }

        if let config = VerifyConfiguration().verify(getdata) {
            do {
                let ok = try validateinput(config)
                if ok {
                    execute(config: config, dryrun: dryrun)
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    func execute(config: SynchronizeConfiguration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        // Start progressview
        showprogressview = true
        let process = ProcessRsync(arguments: arguments,
                                   config: config,
                                   processtermination: processtermination)
        process.executeProcess()
    }

    func abort() {
        InterruptProcess()
    }

    func processtermination(_ stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        Task {
            rsyncoutput.output = await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
            completed = true
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    private func validateinput(_ config: SynchronizeConfiguration) throws -> Bool {
        if config.localCatalog.isEmpty {
            throw ValidateInputQuicktask.localcatalog
        }
        if config.offsiteCatalog.isEmpty {
            throw ValidateInputQuicktask.remotecatalog
        }
        if config.offsiteUsername.isEmpty {
            throw ValidateInputQuicktask.offsiteusername
        }
        if config.offsiteServer.isEmpty {
            throw ValidateInputQuicktask.offsiteserver
        }
        return true
    }
}
