//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_lenght

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @Binding var reload: Bool
    @StateObject private var parameters = ObserveableParametersRsync()
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        ConfigurationsList(selectedconfig: $parameters.configuration.onChange { rsyncOSXData.update() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        HStack {
            VStack(alignment: .leading) {
                EditRsyncParameter(550, $parameters.parameter8.wrappedValue, $parameters.parameter8.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter9.wrappedValue, $parameters.parameter9.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter10.wrappedValue, $parameters.parameter10.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter11.wrappedValue, $parameters.parameter11.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter12.wrappedValue, $parameters.parameter12.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter13.wrappedValue, $parameters.parameter13.onChange {
                    parameters.inputchangedbyuser = true
                })
                EditRsyncParameter(550, $parameters.parameter14.wrappedValue, $parameters.parameter14.onChange {
                    parameters.inputchangedbyuser = true
                })
            }

            VStack(alignment: .leading) {
                Section(header: headerssh) {
                    setsshpath

                    setsshport
                }
            }
        }

        Spacer()

        HStack {
            Spacer()

            Button(NSLocalizedString("Linux", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("FreeBSD", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Daemon", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Backup", comment: "SidebarRsyncParameter")) {}
                .buttonStyle(PrimaryButtonStyle())

            saveparameters
        }
    }

    // Save usersetting is changed
    var saveparameters: some View {
        HStack {
            if parameters.isDirty {
                Button(NSLocalizedString("Save", comment: "usersetting")) { saversyncparameters() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "usersetting")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!parameters.isDirty)
    }

    // Ssh header
    var headerssh: some View {
        Text(NSLocalizedString("Set ssh keypath and identityfile", comment: "ssh settings"))
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Local ssh keypath and identityfile", comment: "settings"), $parameters.sshkeypathandidentityfile.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Local ssh port", comment: "settings"), $parameters.sshport.onChange {
            parameters.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
    }
}

extension RsyncParametersView {
    func saversyncparameters() {}
}

/*
 @IBAction func removecompressparameter(_: NSButton) {
     if let index = self.index() {
         switch self.compressparameter.state {
         case .on:
             self.configurations?.removecompressparameter(index: index, delete: true)
         case .off:
             self.configurations?.removecompressparameter(index: index, delete: false)
         default:
             break
         }
         self.param3.stringValue = self.configurations?.getConfigurations()?[index].parameter3 ?? ""
     }
 }

 @IBAction func removeesshparameter(_: NSButton) {
     if let index = self.index() {
         switch self.esshparameter.state {
         case .on:
             self.configurations?.removeesshparameter(index: index, delete: true)
             self.param5.stringValue = self.configurations?.getConfigurations()?[index].parameter5 ?? ""
         case .off:
             self.configurations?.removeesshparameter(index: index, delete: false)
             self.param5.stringValue = (self.configurations?.getConfigurations()?[index].parameter5 ?? "") + " ssh"
         default:
             break
         }
     }
 }

 @IBAction func removedeleteparameter(_: NSButton) {
     if let index = self.index() {
         switch self.deleteparamater.state {
         case .on:
             self.configurations?.removeedeleteparameter(index: index, delete: true)
         case .off:
             self.configurations?.removeedeleteparameter(index: index, delete: false)
         default:
             break
         }
         self.param4.stringValue = self.configurations?.getConfigurations()?[index].parameter4 ?? ""
     }
 }

 // Function for enabling backup of changed files in a backup catalog.
 // Parameters are appended to last two parameters (12 and 13).
 @IBAction func backup(_: NSButton) {
     if let index = self.index() {
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             switch self.backupbutton.state {
             case .on:
                 self.initcombox(combobox: self.combo12, index: param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).0)
                 self.param12.stringValue = param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[0]).1
                 let hiddenID = self.configurations?.gethiddenID(index: (self.index())!)
                 guard (hiddenID ?? -1) > -1 else { return }
                 let localcatalog = self.configurations?.getResourceConfiguration(hiddenID ?? -1, resource: .localCatalog)
                 let localcatalogParts = (localcatalog as AnyObject).components(separatedBy: "/")
                 self.initcombox(combobox: self.combo13, index: param.indexandvaluersyncparameter(SuffixstringsRsyncParameters().backupstrings[1]).0)
                 self.param13.stringValue = "../backup" + "_" + localcatalogParts[localcatalogParts.count - 2]
             case .off:
                 self.initcombox(combobox: self.combo12, index: 0)
                 self.param12.stringValue = ""
                 self.initcombox(combobox: self.combo13, index: 0)
                 self.param13.stringValue = ""
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default: break
             }
         }
     }
 }

 // Function for enabling suffix date + time changed files.
 // Parameters are appended to last parameter (14).
 @IBOutlet var suffixButton: NSButton!
 @IBAction func suffix(_: NSButton) {
     if let index = self.index() {
         self.suffixButton2.state = .off
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             switch self.suffixButton.state {
             case .on:
                 let suffix = SuffixstringsRsyncParameters().suffixstringfreebsd
                 self.initcombox(combobox: self.combo14, index: param.indexandvaluersyncparameter(suffix).0)
                 self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
             case .off:
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default:
                 break
             }
         }
     }
 }

 @IBOutlet var suffixButton2: NSButton!
 @IBAction func suffix2(_: NSButton) {
     if let index = self.index() {
         if let configurations: [Configuration] = self.configurations?.getConfigurations() {
             let param = ComboboxRsyncParameters(config: configurations[index])
             self.suffixButton.state = .off
             switch self.suffixButton2.state {
             case .on:
                 let suffix = SuffixstringsRsyncParameters().suffixstringlinux
                 self.initcombox(combobox: self.combo14, index: param.indexandvaluersyncparameter(suffix).0)
                 self.param14.stringValue = param.indexandvaluersyncparameter(suffix).1
             case .off:
                 self.initcombox(combobox: self.combo14, index: 0)
                 self.param14.stringValue = ""
             default:
                 break
             }
         }
     }
 }

 */
