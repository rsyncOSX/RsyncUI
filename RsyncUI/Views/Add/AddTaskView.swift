//
//  AddConfigurationView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//
// swiftlint:disable file_length type_body_length

import SwiftUI

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddTaskView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var selectedconfig: Configuration?
    @State private var selecteduuids = Set<Configuration.ID>()

    var choosecatalog = true

    enum AddConfigurationField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case backupIDField
    }

    @StateObject var newdata = ObserveableAddConfigurations()
    @FocusState private var focusField: AddConfigurationField?
    // Modale view
    @State private var modalview = false

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        pickerselecttypeoftask

                        if newdata.selectedrsynccommand == .syncremote {
                            VStack(alignment: .leading) { localandremotecatalogsyncremote }

                        } else {
                            VStack(alignment: .leading) { localandremotecatalog }
                        }

                        VStack(alignment: .leading) {
                            ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""),
                                              $newdata.donotaddtrailingslash)
                        }

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }

                        Spacer()

                        HStack {
                            localcatalogspicker

                            remoteuserpicker

                            remoteserverpicker
                        }

                        Spacer()
                    }

                    // Column 2

                    VStack(alignment: .leading) {
                        ListofTasksLightView(
                            selecteduuids: $selecteduuids.onChange {
                                let selected = rsyncUIdata.configurations?.filter { config in
                                    selecteduuids.contains(config.id)
                                }
                                if (selected?.count ?? 0) == 1 {
                                    if let config = selected {
                                        selectedconfig = config[0]
                                        newdata.updateview(selectedconfig)
                                    }
                                } else {
                                    selectedconfig = nil
                                    newdata.updateview(selectedconfig)
                                }
                            }
                        )

                        HStack {
                            profilebutton

                            updatebutton
                        }
                    }
                }

                // Present when either added, updated or profile created, deleted
                if newdata.added == true { notifyadded }
                if newdata.updated == true { notifyupdated }
                if newdata.created == true { notifycreated }
                if newdata.deleted == true { notifydeleted }
                if newdata.deletedefaultprofile == true { cannotdeletedefaultprofile }
            }
        }
        .lineSpacing(2)
        .padding()
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .backupIDField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                if newdata.selectedconfig == nil {
                    addconfig()
                } else {
                    validateandupdate()
                }
                focusField = nil
            case .backupIDField:
                if newdata.remotestorageislocal == true,
                   newdata.selectedconfig == nil
                {
                    addconfig()
                } else {
                    focusField = .remoteuserField
                }
            default:
                return
            }
        }
        .sheet(isPresented: $modalview) {
            AddProfileView(selectedprofile: $selectedprofile,
                           reload: $reload,
                           modalview: $modalview)
                .frame(width: 400, height: 200)
        }
    }

    var profilebutton: some View {
        Button("Profile") {
            modalview = true
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    var updatebutton: some View {
        HStack {
            // Add or Update button
            if newdata.selectedconfig == nil {
                Button("Add") {
                    addconfig()
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Update") {
                    validateandupdate()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""),
                  $newdata.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
    }

    var setlocalcatalog: some View {
        EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""),
                  $newdata.localcatalog)
            .focused($focusField, equals: .localcatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremotecatalog: some View {
        EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""),
                  $newdata.remotecatalog)
            .focused($focusField, equals: .remotecatalogField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalog } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .focused($focusField, equals: .localcatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalog } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .focused($focusField, equals: .remotecatalogField)
                        .textContentType(.none)
                        .submitLabel(.continue)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            HStack {
                // localcatalog
                if newdata.selectedconfig == nil { setlocalcatalogsyncremote } else {
                    EditValue(300, nil, $newdata.localcatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.localCatalog {
                                newdata.localcatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.localcatalog, choosecatalog: choosecatalog)
            }
            HStack {
                // remotecatalog
                if newdata.selectedconfig == nil { setremotecatalogsyncremote } else {
                    EditValue(300, nil, $newdata.remotecatalog)
                        .onAppear(perform: {
                            if let catalog = newdata.selectedconfig?.offsiteCatalog {
                                newdata.remotecatalog = catalog
                            }
                        })
                }
                OpencatalogView(catalog: $newdata.remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var setID: some View {
        EditValue(300, NSLocalizedString("Add synchronize ID", comment: ""),
                  $newdata.backupID)
            .focused($focusField, equals: .backupIDField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValue(300, nil, $newdata.backupID)
                    .focused($focusField, equals: .backupIDField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(300, NSLocalizedString("Add remote user", comment: ""),
                  $newdata.remoteuser)
            .focused($focusField, equals: .remoteuserField)
            .textContentType(.none)
            .submitLabel(.continue)
    }

    var setremoteserver: some View {
        EditValue(300, NSLocalizedString("Add remote server", comment: ""),
                  $newdata.remoteserver)
            .focused($focusField, equals: .remoteserverField)
            .textContentType(.none)
            .submitLabel(.return)
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValue(300, nil, $newdata.remoteuser)
                    .focused($focusField, equals: .remoteuserField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let user = newdata.selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
            }
            // Remote server
            if newdata.selectedconfig == nil { setremoteserver } else {
                EditValue(300, nil, $newdata.remoteserver)
                    .focused($focusField, equals: .remoteserverField)
                    .textContentType(.none)
                    .submitLabel(.return)
                    .onAppear(perform: {
                        if let server = newdata.selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch newdata.selectedconfig?.task {
        case SharedReference.shared.synchronize:
            return .synchronize
        case SharedReference.shared.syncremote:
            return .syncremote
        case SharedReference.shared.snapshot:
            return .snapshot
        default:
            return .synchronize
        }
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "") + ":",
               selection: $newdata.selectedrsynccommand)
        {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.selectedconfig, perform: { _ in
                newdata.selectedrsynccommand = selectpickervalue
            })
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 140)
    }

    var notifyadded: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Added"), subTitle: Optional(""))
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Updated"), subTitle: Optional(""))
    }

    var notifycreated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Created"), subTitle: Optional(""))
    }

    var notifydeleted: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Deleted"), subTitle: Optional(""))
    }

    var cannotdeletedefaultprofile: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional("Cannot delete default profile"), subTitle: Optional(""))
    }

    var configurations: [Configuration]? {
        return rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations()
    }

    var assist: Assist? {
        return Assist(configurations: rsyncUIdata.configurations)
    }

    var localcatalogspicker: some View {
        VStack(alignment: .trailing) {
            Text("Local catalogs")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistlocalcatalog) {
                Text("").tag("")
                if let catalogs = assist?.catalogs {
                    ForEach(catalogs.sorted(by: <), id: \.self) { catalog in
                        Text(catalog)
                            .tag(catalog)
                    }
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
        }
    }

    var remoteuserpicker: some View {
        VStack(alignment: .trailing) {
            Text("Remote user")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistremoteuser) {
                Text("").tag("")
                if let remoteusers = assist?.remoteusers {
                    ForEach(remoteusers.sorted(by: <), id: \.self) { remoteuser in
                        Text(remoteuser)
                            .tag(remoteuser)
                    }
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
        }
    }

    var remoteserverpicker: some View {
        VStack(alignment: .trailing) {
            Text("Remote server")
                .font(Font.footnote)
            Picker("", selection: $newdata.assistremoteserver) {
                Text("").tag("")
                if let remoteservers = assist?.remoteservers {
                    ForEach(remoteservers.sorted(by: <), id: \.self) { remoteserver in
                        Text(remoteserver)
                            .tag(remoteserver)
                    }
                }
            }
            .frame(width: 93)
            .accentColor(.blue)
        }
    }

    var labelprofiletask: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                modalview = true
            })
    }
}

extension AddTaskView {
    func addconfig() {
        newdata.addconfig(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.added == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.added = false
            }
        }
    }

    func validateandupdate() {
        newdata.validateandupdate(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.updated == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.updated = false
            }
        }
    }
}
