import SwiftUI

struct QuicktaskFormView: View {
    @Binding var localcatalog: String
    @Binding var remotecatalog: String
    @Binding var selectedrsynccommand: TypeofTaskQuictask
    @Binding var remoteuser: String
    @Binding var remoteserver: String
    @Binding var trailingslashoptions: TrailingSlash
    @Binding var dryrun: Bool
    @Binding var catalogorfile: Bool
    @Binding var selectedhomecatalog: Catalog.ID?

    let homecatalogs: [Catalog]
    let localhome: String

    @FocusState var focusField: QuicktaskView.QuicktaskField?

    var body: some View {
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
                            try? await Task.sleep(seconds: 1)
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
                            case "notSelected":
                                self.selectedrsynccommand = TypeofTaskQuictask.notSelected
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
                        .animation(.easeInOut(duration: 0.35), value: dryrun)

                    Toggle("File(off) or Folder(on)", isOn: $catalogorfile)
                        .toggleStyle(.switch)
                        .animation(.easeInOut(duration: 0.35), value: catalogorfile)
                        .onChange(of: catalogorfile) {
                            if catalogorfile {
                                trailingslashoptions = .do_not_add
                            } else {
                                trailingslashoptions = .add
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

            if selectedrsynccommand == .synchronize || selectedrsynccommand == .notSelected {
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
    }
}
