//
//  AddPostandPreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct AddPreandPostView: View {
    @SwiftUI.Environment(RsyncUIconfigurations.self) private var rsyncUIdata
    @SwiftUI.Environment(Profilenames.self) private var profilenames
    @SwiftUI.Environment(Dataischanged.self) private var dataischanged
    @State private var newdata = ObservablePreandPostTask()

    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var selectedconfig: Configuration?
    @State private var selecteduuids = Set<Configuration.ID>()

    // Reload and show table data
    @State private var showtableview: Bool = true

    var choosecatalog = false

    enum PreandPostTaskField: Hashable {
        case pretaskField
        case posttaskField
    }

    @FocusState private var focusField: PreandPostTaskField?

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        pretaskandtoggle

                        posttaskandtoggle

                        HStack {
                            if newdata.selectedconfig == nil { disablehaltshelltasksonerror } else {
                                ToggleViewDefault(NSLocalizedString("Halt on error", comment: ""), $newdata.haltshelltasksonerror)
                                    .onAppear(perform: {
                                        if newdata.selectedconfig?.haltshelltasksonerror == 1 {
                                            newdata.haltshelltasksonerror = true
                                        } else {
                                            newdata.haltshelltasksonerror = false
                                        }
                                    })
                            }
                        }

                        Spacer()
                    }

                    // Column 2

                    VStack(alignment: .leading) {
                        if showtableview {
                            ListofTasksLightView(selecteduuids: $selecteduuids)
                                .onChange(of: selecteduuids) {
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
                            updatebutton
                        } else {
                            notifyupdated
                        }
                    }
                }
            }
        }
        .lineSpacing(2)
        .padding()
        .onSubmit {
            switch focusField {
            case .pretaskField:
                focusField = .posttaskField
            case .posttaskField:
                newdata.enablepre = true
                newdata.enablepost = true
                newdata.haltshelltasksonerror = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    validateandupdate()
                }
                focusField = nil
            default:
                return
            }
        }
        .onAppear {
            if dataischanged.dataischanged {
                showtableview = false
                dataischanged.dataischanged = false
            }
        }
        .alert(isPresented: $newdata.alerterror,
               content: { Alert(localizedError: newdata.error)
               })
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Updated"), subTitle: Optional(""))
            .onAppear(perform: {
                // Show updated for 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showtableview = true
                }
            })
            .frame(maxWidth: .infinity)
    }

    var updatebutton: some View {
        HStack {
            if newdata.selectedconfig == nil {
                Button("Update") {
                    // No update
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

    var setpretask: some View {
        EditValue(250, NSLocalizedString("Add pretask", comment: ""), $newdata.pretask)
    }

    var setposttask: some View {
        EditValue(250, NSLocalizedString("Add posttask", comment: ""), $newdata.posttask)
    }

    var disablepretask: some View {
        ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepre)
    }

    var disableposttask: some View {
        ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepost)
    }

    var pretaskandtoggle: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                // Enable pretask
                if newdata.selectedconfig == nil { disablepretask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepre)
                        .onAppear(perform: {
                            if newdata.selectedconfig?.executepretask == 1 {
                                newdata.enablepre = true
                            } else {
                                newdata.enablepre = false
                            }
                        })
                }

                // Pretask

                HStack {
                    if newdata.selectedconfig == nil { setpretask } else {
                        EditValue(250, nil, $newdata.pretask)
                            .focused($focusField, equals: .pretaskField)
                            .textContentType(.none)
                            .submitLabel(.continue)
                            .onAppear(perform: {
                                if let task = newdata.selectedconfig?.pretask {
                                    newdata.pretask = task
                                }
                            })
                    }

                    OpencatalogView(catalog: $newdata.pretask, choosecatalog: choosecatalog)
                }
            }
        }
    }

    var posttaskandtoggle: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                // Enable posttask
                if newdata.selectedconfig == nil { disableposttask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepost)
                        .onAppear(perform: {
                            if newdata.selectedconfig?.executeposttask == 1 {
                                newdata.enablepost = true
                            } else {
                                newdata.enablepost = false
                            }
                        })
                }

                // Posttask

                HStack {
                    if newdata.selectedconfig == nil { setposttask } else {
                        EditValue(250, nil, $newdata.posttask)
                            .focused($focusField, equals: .posttaskField)
                            .textContentType(.none)
                            .submitLabel(.continue)
                            .onAppear(perform: {
                                if let task = newdata.selectedconfig?.posttask {
                                    newdata.posttask = task
                                }
                            })
                    }
                    OpencatalogView(catalog: $newdata.posttask, choosecatalog: choosecatalog)
                }
            }
        }
    }

    var disablehaltshelltasksonerror: some View {
        ToggleViewDefault(NSLocalizedString("Halt on error", comment: ""),
                          $newdata.haltshelltasksonerror)
    }

    var profile: String? {
        return rsyncUIdata.profile
    }

    var configurations: [Configuration]? {
        return rsyncUIdata.getallconfigurations()
    }
}

extension AddPreandPostView {
    func validateandupdate() {
        newdata.validateandupdate(profile, configurations)
        reload = newdata.reload
        showtableview = false
        dataischanged.dataischanged = true
    }
}

// swiftlint:enable line_length
