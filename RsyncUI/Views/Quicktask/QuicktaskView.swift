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
    @State var localcatalog: String = ""
    @State var remotecatalog: String = ""
    @State var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State var remoteuser: String = ""
    @State var remoteserver: String = ""
    @State var trailingslashoptions: TrailingSlash = .add
    @State var dryrun: Bool = true
    @State var catalogorfile: Bool = true
    @State var focusaborttask: Bool = false

    @AppStorage("quicklocalcatalog") var quicklocalcatalog: String = ""
    @AppStorage("quickremotecatalog") var quickremotecatalog: String = ""
    @AppStorage("quickselectedrsynccommand") var quickselectedrsynccommand: String = ""

    @AppStorage("quickremoteuser") var quickremoteuser: String = ""
    @AppStorage("quickremoteserver") var quickremoteserver: String = ""

    @AppStorage("quicktrailingslashoptions") var quicktrailingslashoptions: String = ""
    @AppStorage("quickcatalogorfile") var quickcatalogorfile: Bool = true

    // Executed labels
    @State var showprogressview = false
    @State var rsyncoutput = ObservableRsyncOutput()
    // Focus buttons from the menu
    @State var Bool = false
    @State var focusstartexecution: Bool = false
    // Completed task
    @State var completed: Bool = false
    // Progress and max if estimate first
    @State var progress: Double = 0
    @State var max: Double = 0

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState var focusField: QuicktaskField?

    @State var selectedhomecatalog: Catalog.ID?
    @State var selectedAttachedVolume: AttachedVolume.ID?
    @State var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalog]

    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Parameters to Task")
                    .font(.title3)
                    .fontWeight(.bold)) {
                        HStack {
                            Picker("Action",
                                   selection: $selectedrsynccommand) {
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
                                    switch selectedrsynccommand as? String {
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

                            Spacer()

                            Picker("Trailing /",
                                   selection: $trailingslashoptions) {
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
                                    guard let trailing = trailingslashoptions as? String else { return }
                                    switch trailing {
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
                                        catalogorfile = quickcatalogorfile as? Bool ?? false
                                    }
                                }
                        }
                    }
                if selectedrsynccommand == .synchronize || selectedrsynccommand == .not_selected {
                    Section(header: Text("Source and destination")
                        .font(.title3)
                        .fontWeight(.bold)) {
                            HStack {
                                EditValueScheme(300, "Add Source folder - required", $localcatalog)
                                    .focused($focusField, equals: .localcatalogField)
                                    .textContentType(.none)
                                    .submitLabel(.continue)
                                    .onChange(of: localcatalog) {
                                        UserDefaults.standard.set(localcatalog, forKey: "quicklocalcatalog")
                                    }
                                    .onAppear {
                                        if let quicklocalcatalog = UserDefaults.standard.value(forKey: "quicklocalcatalog") {
                                            if let catalog = quicklocalcatalog as? String {
                                                localcatalog = catalog
                                            }
                                        }
                                    }

                                Picker("", selection: $selectedhomecatalog) {
                                    Text("Home Catalogs (source)")
                                        .tag(nil as Catalog.ID?)
                                    ForEach(homecatalogs, id: \.self) { catalog in
                                        Text(catalog.name)
                                            .tag(catalog.id)
                                    }
                                }
                                .frame(width: 300)
                                .onChange(of: selectedhomecatalog) {
                                    if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                                        localcatalog = localhome + homecatalogs[index].name
                                    }
                                }
                            }

                            // remotecatalog
                            HStack {
                                EditValueScheme(300, "Add Destination folder - required", $remotecatalog)
                                    .focused($focusField, equals: .remotecatalogField)
                                    .textContentType(.none)
                                    .submitLabel(.continue)
                                    .onChange(of: remotecatalog) {
                                        UserDefaults.standard.set(remotecatalog, forKey: "quickremotecatalog")
                                    }
                                    .onAppear {
                                        if let quickremotecatalog = UserDefaults.standard.value(forKey: "quickremotecatalog") {
                                            if let catalog = quickremotecatalog as? String {
                                                remotecatalog = catalog
                                            }
                                        }
                                    }
                            }
                        }
                } else {
                    Section(header: Text("Source and destination")
                        .font(.title3)
                        .fontWeight(.bold)) {
                            // remotecatalog
                            HStack {
                                EditValueScheme(300, "Add Destination folder - required", $remotecatalog)
                                    .focused($focusField, equals: .remotecatalogField)
                                    .textContentType(.none)
                                    .submitLabel(.continue)
                                    .onChange(of: remotecatalog) {
                                        UserDefaults.standard.set(remotecatalog, forKey: "quickremotecatalog")
                                    }
                                    .onAppear {
                                        if let quickremotecatalog = UserDefaults.standard.value(forKey: "quickremotecatalog") {
                                            if let catalog = quickremotecatalog as? String {
                                                remotecatalog = catalog
                                            }
                                        }
                                    }

                                Picker("", selection: $selectedhomecatalog) {
                                    Text("Home Catalogs (destination)")
                                        .tag(nil as Catalog.ID?)
                                    ForEach(homecatalogs, id: \.self) { catalog in
                                        Text(catalog.name)
                                            .tag(catalog.id)
                                    }
                                }
                                .frame(width: 300)
                                .onChange(of: selectedhomecatalog) {
                                    if let index = homecatalogs.firstIndex(where: { $0.id == selectedhomecatalog }) {
                                        remotecatalog = localhome.appending("/") + homecatalogs[index].name
                                    }
                                }
                            }

                            // localcatalog
                            HStack {
                                EditValueScheme(300, "Add Source folder - required", $localcatalog)
                                    .focused($focusField, equals: .localcatalogField)
                                    .textContentType(.none)
                                    .submitLabel(.continue)
                                    .onChange(of: localcatalog) {
                                        UserDefaults.standard.set(localcatalog, forKey: "quicklocalcatalog")
                                    }
                                    .onAppear {
                                        if let quicklocalcatalog = UserDefaults.standard.value(forKey: "quicklocalcatalog") {
                                            if let catalog = quicklocalcatalog as? String {
                                                localcatalog = catalog
                                            }
                                        }
                                    }
                            }
                        }
                }

                Section(header: Text("Remote user and server")
                    .font(.title3)
                    .fontWeight(.bold)) {
                        // Remote user
                        EditValueScheme(300, "Add remote user - required", $remoteuser)
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
                        EditValueScheme(300, "Add remote server - required", $remoteserver)
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

            if showprogressview { SynchronizeProgressView(max: max, progress: progress, statusText: "Synchronizing...") }
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
        .toolbar { toolbarContent }
        .padding()
        .navigationTitle("Quicktask - only for remote server")
        .navigationDestination(isPresented: $completed) {
            OutputRsyncView(output: rsyncoutput.output ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear {
                getConfigAndExecute()
            }
    }

    var localhome: String {
        URL.userHomeDirectoryURLPath?.path() ?? ""
    }
}
