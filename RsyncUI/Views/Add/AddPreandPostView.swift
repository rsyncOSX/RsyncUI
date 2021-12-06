//
//  AddPostandPreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//
// swiftlint:disable line_length

import AlertToast
import SwiftUI

struct AddPreandPostView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    var choosecatalog = false

    enum PreandPostTaskField: Hashable {
        case pretaskField
        case posttaskField
    }

    @StateObject var newdata = ObserveablePreandPostTask()
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

                if newdata.updated == true { notifyupdated }
            }

            updatebutton

            Spacer()
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
            HStack {
                // Enable pretask
                if newdata.selectedconfig == nil { disablepretask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepre.onChange {})
                        .onAppear(perform: {
                            if newdata.selectedconfig?.executepretask == 1 {
                                newdata.enablepre = true
                            } else {
                                newdata.enablepre = false
                            }
                        })
                }

                // Pretask

                if newdata.selectedconfig == nil { setpretask } else {
                    EditValue(250, nil, $newdata.pretask.onChange {})
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

    var posttaskandtoggle: some View {
        VStack(alignment: .leading) {
            HStack {
                // Enable posttask
                if newdata.selectedconfig == nil { disableposttask } else {
                    ToggleViewDefault(NSLocalizedString("Enable", comment: ""), $newdata.enablepost.onChange {})
                        .onAppear(perform: {
                            if newdata.selectedconfig?.executeposttask == 1 {
                                newdata.enablepost = true
                            } else {
                                newdata.enablepost = false
                            }
                        })
                }

                // Posttask

                if newdata.selectedconfig == nil { setposttask } else {
                    EditValue(250, nil, $newdata.posttask.onChange {})
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

    var disablehaltshelltasksonerror: some View {
        ToggleViewDefault(NSLocalizedString("Halt on error", comment: ""),
                          $newdata.haltshelltasksonerror.onChange {})
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("Updated", comment: "")), subTitle: Optional(""))
    }

    var profile: String? {
        return rsyncUIdata.profile
    }

    var configurations: [Configuration]? {
        return rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations()
    }
}

extension AddPreandPostView {
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
