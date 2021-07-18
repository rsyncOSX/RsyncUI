//
//  AddConfigurationView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//

import AlertToast
import SwiftUI

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    enum AddConfigurationField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
        case backupIDField
        case newprofileField
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
                        } else {
                            VStack(alignment: .leading) { localandremotecatalog }
                        }

                        VStack(alignment: .leading) {
                            ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""), $newdata.donotaddtrailingslash)
                        }

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2

                    VStack(alignment: .leading) {
                        ConfigurationsListSmall(selectedconfig: $newdata.selectedconfig.onChange {
                            newdata.updateview()
                        })
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

            Spacer()

            VStack {
                HStack {
                    adddeleteprofile

                    Spacer()

                    updatebutton
                }
            }
        }
        .lineSpacing(2)
        .padding()
        .onAppear(perform: {
            if selectedprofile == nil {
                selectedprofile = "Default profile"
            }
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
            case .newprofileField:
                createprofile()
                focusField = .localcatalogField
            default:
                return
            }
        }
    }

    var updatebutton: some View {
        HStack {
            // Add or Update button
            if newdata.selectedconfig == nil {
                Button("Add") { addconfig() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                if newdata.inputchangedbyuser == true {
                    Button("Update") { validateandupdate() }
                        .buttonStyle(SaveButtonStyle())
                } else {
                    Button("Update") {}
                        .buttonStyle(PrimaryButtonStyle())
                }
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
            // localcatalog
            if newdata.selectedconfig == nil { setlocalcatalog } else {
                EditValue(300, nil, $newdata.localcatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.localCatalog {
                            newdata.localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if newdata.selectedconfig == nil { setremotecatalog } else {
                EditValue(300, nil, $newdata.remotecatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.offsiteCatalog {
                            newdata.remotecatalog = catalog
                        }
                    })
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            if newdata.selectedconfig == nil {
                setlocalcatalogsyncremote
            } else {
                EditValue(300, nil, $newdata.localcatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.localCatalog {
                            newdata.localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if newdata.selectedconfig == nil {
                setremotecatalogsyncremote
            } else {
                EditValue(300, nil, $newdata.remotecatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .onAppear(perform: {
                        if let catalog = newdata.selectedconfig?.offsiteCatalog {
                            newdata.remotecatalog = catalog
                        }
                    })
            }
        }
    }

    // Headers (in sections)

    var adddeleteprofile: some View {
        HStack {
            Button("Create") { createprofile() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Delete") { newdata.showAlertfordelete = true }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(isPresented: $newdata.showAlertfordelete,
                                             delete: $newdata.confirmdeleteselectedprofile,
                                             profile: $rsyncUIdata.profile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }

            EditValue(150, NSLocalizedString("New profile", comment: ""),
                      $newdata.newprofile)
                .focused($focusField, equals: .newprofileField)
                .textContentType(.none)
                .submitLabel(.return)
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
                EditValue(300, nil, $newdata.backupID.onChange {
                    newdata.inputchangedbyuser = true
                })
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
                EditValue(300, nil, $newdata.remoteuser.onChange {
                    newdata.inputchangedbyuser = true
                })
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
                EditValue(300, nil, $newdata.remoteserver.onChange {
                    newdata.inputchangedbyuser = true
                })
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
        return rsyncUIdata.rsyncdata?.configurationData.getallconfigurations()
    }
}

extension AddConfigurationView {
    func addconfig() {
        newdata.addconfig(selectedprofile, configurations)
        reload = newdata.reload
        if newdata.added == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.added = false
            }
        }
    }

    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
        if newdata.created == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.created = false
            }
        }
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
        if newdata.deleted == true {
            profilenames.update()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deleted = false
            }
        }
        if newdata.deletedefaultprofile == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deletedefaultprofile = false
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
