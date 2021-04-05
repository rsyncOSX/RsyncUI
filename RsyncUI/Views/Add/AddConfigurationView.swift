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
// swiftlint:disable file_length multiple_closures_with_trailing_closure

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
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var profilenames: Profilenames

    @Binding var selectedprofile: String?

    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTask.synchronize
    @State private var donotaddtrailingslash: Bool = false

    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var backupID: String = ""

    // Sheet for selecting configuration if edit
    @State private var selectedconfig: Configuration?
    @State private var presentsheet: Bool = false
    // Set reload = true after update
    @Binding var reload: Bool
    // New profile
    @State private var newprofile: String = ""
    // Added and updated labels
    @State private var added = false
    @State private var updated = false
    @State private var created = false

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

                        VStack(alignment: .leading) { backupid }

                        VStack(alignment: .leading) { remoteuserandserver }
                    }

                    // Column 2
                    VStack(alignment: .leading) {
                        ToggleView(NSLocalizedString("Don´t add /", comment: "settings"), $donotaddtrailingslash)

                        HStack {
                            EditValue(100, NSLocalizedString("New profile", comment: "settings"), $newprofile)

                            Button(action: { createprofile() }) { Image(systemName: "plus") }
                                .buttonStyle(GrayCircleButtonStyle())
                        }
                    }

                    // For center
                    Spacer()
                }

                HStack {
                    // Present when either added, updated or profile created
                    if added == true { notifyadded }
                    if updated == true { notifyupdated }
                    if created == true { notifycreated }
                }
            }
            VStack {
                HStack {
                    Spacer()
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

                    Button(NSLocalizedString("Select", comment: "Select button")) { selectconfig() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .lineSpacing(2)
        .padding()
        .sheet(isPresented: $presentsheet) { configsheet }
    }

    // Add and edit text values
    var setlocalcatalog: some View {
        EditValue(250, NSLocalizedString("Add localcatalog - required", comment: "settings"), $localcatalog)
    }

    var setremotecatalog: some View {
        EditValue(250, NSLocalizedString("Add remotecatalog - required", comment: "settings"), $remotecatalog)
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
                EditValue(250, nil, $localcatalog)
                    .onAppear(perform: {
                        if let catalog = selectedconfig?.localCatalog {
                            localcatalog = catalog
                        }
                    })
            }
            // remotecatalog
            if selectedconfig == nil { setremotecatalog } else {
                EditValue(250, nil, $remotecatalog)
                    .onAppear(perform: {
                        if let catalog = selectedconfig?.offsiteCatalog {
                            remotecatalog = catalog
                        }
                    })
            }
        }
    }

    var setID: some View {
        EditValue(250, NSLocalizedString("Add backup ID", comment: "settings"), $backupID)
    }

    var headerID: some View {
        Text(NSLocalizedString("Backup ID", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var backupid: some View {
        Section(header: headerID) {
            // Backup ID
            if selectedconfig == nil { setID } else {
                EditValue(250, nil, $backupID)
                    .onAppear(perform: {
                        if let id = selectedconfig?.backupID {
                            backupID = id
                        }
                    })
            }
        }
    }

    var setremoteuser: some View {
        EditValue(250, NSLocalizedString("Add remote user", comment: "settings"), $remoteuser)
    }

    var setremoteserver: some View {
        EditValue(250, NSLocalizedString("Add remote server", comment: "settings"), $remoteserver)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            if selectedconfig == nil { setremoteuser } else {
                EditValue(250, nil, $remoteuser)
                    .onAppear(perform: {
                        if let user = selectedconfig?.offsiteUsername {
                            remoteuser = user
                        }
                    })
            }
            // Remote server
            if selectedconfig == nil { setremoteserver } else {
                EditValue(250, nil, $remoteserver)
                    .onAppear(perform: {
                        if let server = selectedconfig?.offsiteServer {
                            remoteserver = server
                        }
                    })
            }
        }
    }

    // Select, if update, configurations for update
    var configsheet: some View {
        SelectConfigurationView(selectedconfig: $selectedconfig, isPresented: $presentsheet)
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
               selection: $selectedrsynccommand) {
            ForEach(TypeofTask.allCases) { Text($0.description)
                .tag($0)
            }
            .onChange(of: selectedconfig, perform: { _ in
                selectedrsynccommand = selectpickervalue
            })
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    var notifyadded: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Added", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var notifyupdated: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Updated", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var notifycreated: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Created", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }
}

extension AddConfigurationView {
    func selectconfig() {
        resetform()
        presentsheet = true
    }

    func addconfig() {
        let getdata = AppendConfig(selectedrsynccommand.rawValue,
                                   localcatalog,
                                   remotecatalog,
                                   donotaddtrailingslash,
                                   remoteuser,
                                   remoteserver,
                                   backupID,
                                   // add post and pretask in it own view, set nil here
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncOSXData.rsyncdata?.profile,
                                     configurations: rsyncOSXData.rsyncdata?.configurationData.getallconfigurations())
            if updateconfigurations.addconfiguration(newconfig) == true {
                reload = true
                added = true
                // Show added for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    added = false
                    resetform()
                }
            }
        }
    }

    func updateconfig() {
        let updateddata = AppendConfig(selectedrsynccommand.rawValue,
                                       localcatalog,
                                       remotecatalog,
                                       donotaddtrailingslash,
                                       remoteuser,
                                       remoteserver,
                                       backupID,
                                       // add post and pretask in it own view, set nil here
                                       nil,
                                       nil,
                                       nil,
                                       nil,
                                       nil,
                                       selectedconfig?.hiddenID ?? -1)
        if let updatedconfig = VerifyConfiguration().verify(updateddata) {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncOSXData.rsyncdata?.profile,
                                     configurations: rsyncOSXData.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(updatedconfig, false)
            reload = true
            updated = true
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updated = false
                resetform()
            }
        }
    }

    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        donotaddtrailingslash = false
        remoteuser = ""
        remoteserver = ""
        backupID = ""
        selectedconfig = nil
    }

    func createprofile() {
        guard newprofile.isEmpty == false else { return }
        let catalogprofile = CatalogProfile()
        let existingprofiles = catalogprofile.getcatalogsasstringnames()
        guard existingprofiles?.contains(newprofile) == false else { return }
        _ = catalogprofile.createprofilecatalog(profile: newprofile)
        selectedprofile = newprofile
        reload = true
        created = true
        // Send update message
        profilenames.update()
        newprofile = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            created = false
            resetform()
        }
    }

    func validateandupdate() {
        // Validate not a snapshot task
        do {
            let validated = try validatenotsnapshottask()
            if validated {
                updateconfig()
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    func updateview() {
        if let config = selectedconfig {
            localcatalog = config.localCatalog
            remotecatalog = config.offsiteCatalog
            remoteuser = config.offsiteUsername
            remoteserver = config.offsiteServer
            backupID = config.backupID
        }
    }

    private func validatenotsnapshottask() throws -> Bool {
        if let config = selectedconfig {
            if config.task == SharedReference.shared.snapshot {
                throw CannotUpdateSnaphotsError.cannotupdate
            } else {
                return true
            }
        }
        return false
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
