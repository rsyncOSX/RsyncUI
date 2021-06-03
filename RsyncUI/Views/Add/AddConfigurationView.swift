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
// swiftlint:disable file_length line_length

import SwiftUI

enum CannotUpdateSnaphotsError: LocalizedError {
    case cannotupdate

    var errorDescription: String? {
        switch self {
        case .cannotupdate:
            return NSLocalizedString("Snapshot tasks cannot be updated", comment: "cannot") + "..."
        }
    }
}

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

    @StateObject var newdata = ObserveableReferenceAddConfigurations()
    /*
     @State private var localcatalog: String = ""
     @State private var remotecatalog: String = ""
     @State private var selectedrsynccommand = TypeofTask.synchronize
     @State private var donotaddtrailingslash: Bool = false

     @State private var remoteuser: String = ""
     @State private var remoteserver: String = ""
     @State private var backupID: String = ""
     */
    // Sheet for selecting configuration if edit
    @State private var selectedconfig: Configuration?
    // Set reload = true after update
    @Binding var reload: Bool
    // New profile
    @State private var newprofile: String = ""
    // Added and updated labels
    @State private var added = false
    @State private var updated = false
    @State private var created = false
    @State private var deleted = false
    @State private var deletedefaultprofile = false
    // Delete profile
    @State private var showAlertfordelete = false
    @State private var confirmdeleteselectedprofile = false

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        pickerselecttypeoftask

                        VStack(alignment: .leading) { localandremotecatalog }

                        VStack(alignment: .leading) { synchronizeid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2
                    VStack(alignment: .leading) {
                        ToggleView(NSLocalizedString("Don´t add /", comment: "settings"), $newdata.donotaddtrailingslash)

                        adddeleteprofile
                    }

                    // Column 3

                    VStack(alignment: .leading) {
                        ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                            updateview()
                        })
                    }

                    // For center
                    Spacer()
                }

                // Present when either added, updated or profile created, deleted
                if added == true { notifyadded }
                if updated == true { notifyupdated }
                if created == true { notifycreated }
                if deleted == true { notifydeleted }
                if deletedefaultprofile == true { cannotdeletedefaultprofile }
            }

            Spacer()

            VStack {
                HStack {
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
            if selectedconfig == nil {
                Button(NSLocalizedString("Add", comment: "Add button")) { addconfig() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(NSLocalizedString("Update", comment: "Update button")) { validateandupdate() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            }
        }
    }

    // Add and edit text values
    var setlocalcatalog: some View {
        EditValue(250, NSLocalizedString("Add localcatalog - required", comment: "settings"),
                  $newdata.localcatalog)
    }

    var setremotecatalog: some View {
        EditValue(250, NSLocalizedString("Add remotecatalog - required", comment: "settings"),
                  $newdata.remotecatalog)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text(NSLocalizedString("Catalog parameters", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            if selectedconfig == nil { setlocalcatalog } else {
                EditValue(250, nil, $newdata.localcatalog)
                    .onAppear(perform: {
                        if let catalog = selectedconfig?.localCatalog {
                            newdata.localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if selectedconfig == nil { setremotecatalog } else {
                EditValue(250, nil, $newdata.remotecatalog)
                    .onAppear(perform: {
                        if let catalog = selectedconfig?.offsiteCatalog {
                            newdata.remotecatalog = catalog
                        }
                    })
            }
        }
    }

    // Headers (in sections)
    var headerprofile: some View {
        Text(NSLocalizedString("Profile", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var adddeleteprofile: some View {
        Section(header: headerprofile) {
            HStack {
                Button(NSLocalizedString("Create", comment: "Add button")) { createprofile() }
                    .buttonStyle(PrimaryButtonStyle())

                Button(NSLocalizedString("Delete", comment: "Add button")) { showAlertfordelete = true }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $showAlertfordelete) {
                        ConfirmDeleteProfileView(isPresented: $showAlertfordelete,
                                                 delete: $confirmdeleteselectedprofile,
                                                 profile: $rsyncUIData.profile)
                            .onDisappear(perform: {
                                deleteprofile()
                            })
                    }
            }

            EditValue(150, NSLocalizedString("New profile", comment: "settings"), $newprofile)
        }
    }

    var setID: some View {
        EditValue(250, NSLocalizedString("Add synchronize ID", comment: "settings"),
                  $newdata.backupID)
    }

    var headerID: some View {
        Text(NSLocalizedString("Synchronize ID", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var synchronizeid: some View {
        Section(header: headerID) {
            // Synchronize ID
            if selectedconfig == nil { setID } else {
                EditValue(250, nil, $newdata.backupID)
                    .onAppear(perform: {
                        if let id = selectedconfig?.backupID {
                            newdata.backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(250, NSLocalizedString("Add remote user", comment: "settings"),
                  $newdata.remoteuser)
    }

    var setremoteserver: some View {
        EditValue(250, NSLocalizedString("Add remote server", comment: "settings"),
                  $newdata.remoteserver)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if selectedconfig == nil { setremoteuser } else {
                EditValue(250, nil, $newdata.remoteuser)
                    .onAppear(perform: {
                        if let user = selectedconfig?.offsiteUsername {
                            newdata.remoteuser = user
                        }
                    })
            }
            // Remote server
            if selectedconfig == nil { setremoteserver } else {
                EditValue(250, nil, $newdata.remoteserver)
                    .onAppear(perform: {
                        if let server = selectedconfig?.offsiteServer {
                            newdata.remoteserver = server
                        }
                    })
            }
        }
    }

    var selectpickervalue: TypeofTask {
        switch selectedconfig?.task {
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
            .onChange(of: selectedconfig, perform: { _ in
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
        AlertToast(type: .error(Color.red), title: Optional(NSLocalizedString("Cannot delete default profile", comment: "settings")), subTitle: Optional(""))
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
        newdata.addconfig()
        if added == true {
            // Show added for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                added = false
            }
        }
    }

    func updateconfig() {
        newdata.updateconfig()
        if updated == true {
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updated = false
            }
        }
    }

    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        if created == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                created = false
            }
        }
    }

    func deleteprofile() {
        newdata.deleteprofile()
        if deleted == true {
            profilenames.update()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                deleted = false
            }
        }
        if deletedefaultprofile == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                deletedefaultprofile = false
            }
        }
    }

    func updateview() {
        newdata.updateview()
    }

    func validateandupdate() {
        newdata.validateandupdate()
    }
}

/*
 TODO:
 - fix that ID can be changed on snapshot tasks.
 */
