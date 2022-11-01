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

    var choosecatalog = true

    enum AddConfigurationField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case backupIDField
        // case newprofileField
    }

    @StateObject var newdata = ObserveableAddConfigurations()
    @FocusState private var focusField: AddConfigurationField?

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
                            // OpencatalogView(catalog: $newdata.localcatalog)

                        } else {
                            VStack(alignment: .leading) { localandremotecatalog }
                            // OpencatalogView(catalog: $newdata.localcatalog)
                        }

                        VStack(alignment: .leading) {
                            ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""),
                                              $newdata.donotaddtrailingslash)
                        }

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2

                    VStack(alignment: .leading) {
                        ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                            newdata.updateview(selectedconfig)
                        }, reload: $reload)
                    }

                    // For center
                    Spacer()
                }

                // Present when either added, updated or profile created, deleted
                if newdata.added == true { notifyadded }
                if newdata.updated == true { notifyupdated }
                if newdata.created == true { notifycreated }
                if newdata.deleted == true { notifydeleted }
                if newdata.deletedefaultprofile == true { cannotdeletedefaultprofile }
            }

            updatebutton

            Spacer()
        }
        .lineSpacing(2)
        .padding()
        .onAppear(perform: {
            focusField = .localcatalogField
        })
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
                    Task {
                        await addconfig()
                    }
                } else {
                    Task {
                        await validateandupdate()
                    }
                }
                focusField = nil
            case .backupIDField:
                if newdata.remotestorageislocal == true,
                   newdata.selectedconfig == nil
                {
                    Task {
                        await addconfig()
                    }
                } else {
                    focusField = .remoteuserField
                }
            default:
                return
            }
        }
    }

    var updatebutton: some View {
        HStack {
            // Add or Update button
            if newdata.selectedconfig == nil {
                Button("Add") {
                    Task {
                        await addconfig()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Update") {
                    Task {
                        await validateandupdate()
                    }
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

    // Headers (in sections)

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
               selection: $newdata.selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: newdata.selectedconfig, perform: { _ in
                newdata.selectedrsynccommand = selectpickervalue
            })
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
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
}

extension AddTaskView {
    func addconfig() async {
        await newdata.addconfig(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.added == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.added = false
            }
        }
    }

    func validateandupdate() async {
        await newdata.validateandupdate(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.updated == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.updated = false
            }
        }
    }
}
