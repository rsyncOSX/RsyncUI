//
//  AddPostandPreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//

import SwiftUI

struct AddPostandPreView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var enablepre: Bool = false
    @State private var enablepost: Bool = false
    @State private var pretask: String = ""
    @State private var posttask: String = ""
    @State private var haltshelltasksonerror: Bool = false

    // Sheet for selecting configuration if edit
    @State private var selectedconfig: Configuration?
    @State private var presentsheet: Bool = false
    // Set reload = true after update
    @Binding var reload: Bool
    // Added and updated labels
    @State private var updated = false

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()

                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerprepost) {
                        pretaskandtoggle

                        posttaskandtoggle
                    }
                }

                // Column 2
                VStack(alignment: .leading) {
                    // Halt posttask on error
                    if selectedconfig == nil { disablehaltshelltasksonerror } else {
                        ToggleView(NSLocalizedString("Halt on error", comment: "settings"), $haltshelltasksonerror)
                            .onAppear(perform: {
                                if selectedconfig?.haltshelltasksonerror == 1 {
                                    haltshelltasksonerror = true
                                } else {
                                    haltshelltasksonerror = false
                                }
                            })
                    }
                }

                // For center
                Spacer()
            }

            VStack {
                HStack {
                    Spacer()

                    // Present when updated
                    if updated == true { notifyupdated }

                    Button(NSLocalizedString("Select", comment: "Select button")) { selectconfig() }
                        .buttonStyle(PrimaryButtonStyle())

                    // Add or Update button
                    if selectedconfig == nil {
                        Button(NSLocalizedString("Update", comment: "Update button")) {}
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
        }
        .lineSpacing(2)
        .padding()
        .sheet(isPresented: $presentsheet) { configsheet }
    }

    var setpretask: some View {
        EditValue(250, NSLocalizedString("Add pretask", comment: "settings"), $pretask)
    }

    var setposttask: some View {
        EditValue(250, NSLocalizedString("Add posttask", comment: "settings"), $posttask)
    }

    var disablepretask: some View {
        ToggleView(NSLocalizedString("Enable", comment: "settings"), $enablepre)
    }

    var disableposttask: some View {
        ToggleView(NSLocalizedString("Enable", comment: "settings"), $enablepost)
    }

    var headerprepost: some View {
        Text(NSLocalizedString("Pre and post task", comment: "settings"))
            .modifier(FixedTag(200, .leading))
    }

    var pretaskandtoggle: some View {
        HStack {
            // Enable pretask
            if selectedconfig == nil { disablepretask } else {
                ToggleView(NSLocalizedString("Enable", comment: "settings"), $enablepre)
                    .onAppear(perform: {
                        if selectedconfig?.executepretask == 1 {
                            enablepre = true
                        } else {
                            enablepre = false
                        }
                    })
            }

            // Pretask
            if selectedconfig == nil { setpretask } else {
                EditValue(250, nil, $pretask)
                    .onAppear(perform: {
                        if let task = selectedconfig?.pretask {
                            pretask = task
                        }
                    })
            }
        }
    }

    var posttaskandtoggle: some View {
        HStack {
            // Enable posttask
            if selectedconfig == nil { disableposttask } else {
                ToggleView(NSLocalizedString("Enable", comment: "settings"), $enablepost)
                    .onAppear(perform: {
                        if selectedconfig?.executeposttask == 1 {
                            enablepost = true
                        } else {
                            enablepost = false
                        }
                    })
            }

            // Posttask
            if selectedconfig == nil { setposttask } else {
                EditValue(250, nil, $posttask)
                    .onAppear(perform: {
                        if let task = selectedconfig?.posttask {
                            posttask = task
                        }
                    })
            }
        }
    }

    // Select configurations for adding post and pretask
    var configsheet: some View {
        SelectConfigurationView(selectedconfig: $selectedconfig, isPresented: $presentsheet)
    }

    var disablehaltshelltasksonerror: some View {
        ToggleView(NSLocalizedString("Halt on error", comment: "settings"), $haltshelltasksonerror)
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
}

extension AddPostandPreView {
    func selectconfig() {
        resetform()
        presentsheet = true
    }

    func updateconfig() {
        // Append default config data to the update,
        // only post and pretask is new
        let updateddata = AppendConfig(selectedconfig?.task ?? "",
                                       selectedconfig?.localCatalog ?? "",
                                       selectedconfig?.offsiteCatalog ?? "",
                                       false,
                                       selectedconfig?.offsiteUsername,
                                       selectedconfig?.offsiteServer,
                                       selectedconfig?.backupID,
                                       enablepre,
                                       pretask,
                                       enablepost,
                                       posttask,
                                       haltshelltasksonerror,
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
        enablepre = false
        pretask = ""
        enablepost = false
        posttask = ""
        haltshelltasksonerror = false
        selectedconfig = nil
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
            if config.pretask != nil {
                if config.executepretask == 1 {
                    enablepre = true
                } else {
                    enablepre = false
                }
                pretask = config.pretask ?? ""
            }
            if config.posttask != nil {
                if config.executeposttask == 1 {
                    enablepost = true
                } else {
                    enablepost = false
                }
                pretask = config.pretask ?? ""
            }
            if config.posttask != nil {
                if config.haltshelltasksonerror == 1 {
                    haltshelltasksonerror = true
                } else {
                    haltshelltasksonerror = false
                }
            }
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
