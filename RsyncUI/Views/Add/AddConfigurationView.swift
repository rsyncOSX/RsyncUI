//
//  AddConfigurationView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//

//
//  AddView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/03/2021.
//

import SwiftUI

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct AddConfigurationView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
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

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2
                    VStack(alignment: .leading) {
                        ToggleView(NSLocalizedString("Don´t add /", comment: "settings"), $newdata.donotaddtrailingslash)
                    }

                    // Column 3

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
    }

    var updatebutton: some View {
        HStack {
            // Add or Update button
            if newdata.selectedconfig == nil {
                Button(NSLocalizedString("Add", comment: "Add button")) { addconfig() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                if newdata.inputchangedbyuser == true {
                    Button(NSLocalizedString("Update", comment: "Update button")) { validateandupdate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red, lineWidth: 5)
                        )
                } else {
                    Button(NSLocalizedString("Update", comment: "Update button")) {}
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    // Add and edit text values
    var setlocalcatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: "settings"),
                  $newdata.localcatalog)
    }

    var setremotecatalogsyncremote: some View {
        EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: "settings"),
                  $newdata.remotecatalog)
    }

    var setlocalcatalog: some View {
        EditValue(300, NSLocalizedString("Add local catalog - required", comment: "settings"),
                  $newdata.localcatalog)
            .textContentType(.none)
    }

    var setremotecatalog: some View {
        EditValue(300, NSLocalizedString("Add remote catalog - required", comment: "settings"),
                  $newdata.remotecatalog)
            .textContentType(.none)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text(NSLocalizedString("Catalog parameters", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            if newdata.selectedconfig == nil { setlocalcatalog } else {
                EditValue(300, nil, $newdata.localcatalog.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
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
                    .textContentType(.none)
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
            Button(NSLocalizedString("Create", comment: "Add button")) { createprofile() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Delete", comment: "Add button")) { newdata.showAlertfordelete = true }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(isPresented: $newdata.showAlertfordelete,
                                             delete: $newdata.confirmdeleteselectedprofile,
                                             profile: $rsyncUIData.profile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }

            EditValue(150, NSLocalizedString("New profile", comment: "settings"),
                      $newdata.newprofile)
                .textContentType(.none)
        }
    }

    var setID: some View {
        EditValue(300, NSLocalizedString("Add synchronize ID", comment: "settings"),
                  $newdata.backupID)
            .textContentType(.none)
    }

    var headerID: some View {
        Text(NSLocalizedString("Synchronize ID", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if newdata.selectedconfig == nil { setID } else {
                EditValue(300, nil, $newdata.backupID.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let id = newdata.selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(300, NSLocalizedString("Add remote user", comment: "settings"),
                  $newdata.remoteuser)
            .textContentType(.none)
    }

    var setremoteserver: some View {
        EditValue(300, NSLocalizedString("Add remote server", comment: "settings"),
                  $newdata.remoteserver)
            .textContentType(.none)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if newdata.selectedconfig == nil { setremoteuser } else {
                EditValue(300, nil, $newdata.remoteuser.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
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
                    .textContentType(.none)
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
        Picker(NSLocalizedString("Task", comment: "AddConfigurationsView") + ":",
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
                   title: Optional(NSLocalizedString("Added",
                                                     comment: "settings")), subTitle: Optional(""))
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("Updated",
                                                     comment: "settings")), subTitle: Optional(""))
    }

    var notifycreated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("Created",
                                                     comment: "settings")), subTitle: Optional(""))
    }

    var notifydeleted: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("Deleted",
                                                     comment: "settings")), subTitle: Optional(""))
    }

    var cannotdeletedefaultprofile: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional(NSLocalizedString("Cannot delete default profile",
                                                     comment: "settings")), subTitle: Optional(""))
    }

    var profile: String? {
        return rsyncUIData.profile
    }

    var configurations: [Configuration]? {
        return rsyncUIData.rsyncdata?.configurationData.getallconfigurations()
    }
}

extension AddConfigurationView {
    func addconfig() {
        newdata.addconfig(profile, configurations)
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
        newdata.deleteprofile(profile)
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
        newdata.validateandupdate(profile, configurations)
        reload = newdata.reload
        if newdata.updated == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.updated = false
            }
        }
    }
}
