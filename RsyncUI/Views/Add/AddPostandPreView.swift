//
//  AddPostandPreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct AddPostandPreView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    enum PreandPostTaskField: Hashable {
        case pretaskField
        case posttaskField
    }

    @StateObject var newdata = ObserveablePreandPostTask()

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
                                ToggleView("Halt on error", $newdata.haltshelltasksonerror)
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
                    .padding()

                    // Column 2
                    VStack(alignment: .leading) {
                        ConfigurationsListSmall(selectedconfig: $newdata.selectedconfig.onChange {
                            newdata.updateview()
                        })

                        Spacer()
                    }
                    // For center
                    Spacer()
                }

                if newdata.updated == true { notifyupdated }
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
            if newdata.selectedconfig == nil {
                Button("Update") {}
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                if newdata.inputchangedbyuser == true {
                    Button("Update") { validateandupdate() }
                        .buttonStyle(PrimaryButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red, lineWidth: 5)
                        )
                } else {
                    Button("Update") {}
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    var setpretask: some View {
        EditValue(250, "Add pretask", $newdata.pretask)
    }

    var setposttask: some View {
        EditValue(250, "Add posttask", $newdata.posttask)
    }

    var disablepretask: some View {
        ToggleView("Enable", $newdata.enablepre)
    }

    var disableposttask: some View {
        ToggleView("Enable", $newdata.enablepost)
    }

    var pretaskandtoggle: some View {
        HStack {
            // Enable pretask
            if newdata.selectedconfig == nil { disablepretask } else {
                ToggleView("Enable", $newdata.enablepre.onChange {
                    newdata.inputchangedbyuser = true
                })
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
                EditValue(250, nil, $newdata.pretask.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let task = newdata.selectedconfig?.pretask {
                            newdata.pretask = task
                        }
                    })
            }
        }
    }

    var posttaskandtoggle: some View {
        HStack {
            // Enable posttask
            if newdata.selectedconfig == nil { disableposttask } else {
                ToggleView("Enable", $newdata.enablepost.onChange {
                    newdata.inputchangedbyuser = true
                })
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
                EditValue(250, nil, $newdata.posttask.onChange {
                    newdata.inputchangedbyuser = true
                })
                    .textContentType(.none)
                    .onAppear(perform: {
                        if let task = newdata.selectedconfig?.posttask {
                            newdata.posttask = task
                        }
                    })
            }
        }
    }

    var disablehaltshelltasksonerror: some View {
        ToggleView("Halt on error",
                   $newdata.haltshelltasksonerror.onChange {
                       newdata.inputchangedbyuser = true
                   })
    }

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Updated"), subTitle: Optional(""))
    }

    var profile: String? {
        return rsyncUIdata.profile
    }

    var configurations: [Configuration]? {
        return rsyncUIdata.rsyncdata?.configurationData.getallconfigurations()
    }
}

extension AddPostandPreView {
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
