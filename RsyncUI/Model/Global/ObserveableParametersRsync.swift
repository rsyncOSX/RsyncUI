//
//  ObserveableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

class ObserveableParametersRsync: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Rsync parameters
    @Published var parameter8: String = ""
    @Published var parameter9: String = ""
    @Published var parameter10: String = ""
    @Published var parameter11: String = ""
    @Published var parameter12: String = ""
    @Published var parameter13: String = ""
    @Published var parameter14: String = ""
    // Selected configuration
    @Published var configuration: Configuration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // If local public sshkeys are present
    @Published var inputchangedbyuser: Bool = false
    // Remove parameters
    @Published var removessh: Bool = false
    @Published var removecompress: Bool = false
    @Published var removedelete: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter8 in
                validate(parameter8)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter9 in
                validate(parameter9)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter10 in
                validate(parameter10)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter11 in
                validate(parameter11)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter12 in
                validate(parameter12)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter13 in
                validate(parameter13)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter14 in
                validate(parameter14)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config { setvalues(config) }
                isDirty = false
            }.store(in: &subscriptions)
        $sshkeypathandidentityfile
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
        $removessh
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] val in
                deletessh(val)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $removedelete
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] val in
                deletedelete(val)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $removecompress
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] val in
                deletecompress(val)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }

    private func validate(_ parameter: String) {
        print(parameter)
    }

    // parameter5
    private func deletessh(_ delete: Bool) {
        if delete {
            configuration?.parameter5 = ""
        } else {
            configuration?.parameter5 = "-e"
        }
    }

    // parameter4
    private func deletedelete(_ delete: Bool) {
        if delete {
            configuration?.parameter4 = ""
        } else {
            configuration?.parameter4 = "--delete"
        }
    }

    // parameter3
    private func deletecompress(_ delete: Bool) {
        if delete {
            configuration?.parameter3 = ""
        } else {
            configuration?.parameter3 = "--compress"
        }
    }

    // SSH identityfile
    private func checksshkeypathbeforesaving(_ keypath: String) throws -> Bool {
        if keypath.first != "~" { throw SshError.noslash }
        let tempsshkeypath = keypath
        let sshkeypathandidentityfilesplit = tempsshkeypath.split(separator: "/")
        guard sshkeypathandidentityfilesplit.count > 2 else { throw SshError.noslash }
        guard sshkeypathandidentityfilesplit[1].count > 1 else { throw SshError.notvalidpath }
        guard sshkeypathandidentityfilesplit[2].count > 1 else { throw SshError.notvalidpath }
        return true
    }

    private func setvalues(_ config: Configuration) {
        parameter8 = config.parameter8 ?? ""
        parameter9 = config.parameter9 ?? ""
        parameter10 = config.parameter10 ?? ""
        parameter11 = config.parameter11 ?? ""
        parameter12 = config.parameter12 ?? ""
        parameter13 = config.parameter13 ?? ""
        parameter14 = config.parameter14 ?? ""
        if let configsshport = config.sshport {
            sshport = String(configsshport)
        }
        sshkeypathandidentityfile = config.sshkeypathandidentityfile ?? ""
        // set delete toggles
        if config.parameter3.isEmpty { removecompress = true }
        if config.parameter4.isEmpty { removedelete = true }
        if config.parameter5.isEmpty { removessh = true }
    }

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                configuration?.sshkeypathandidentityfile = keypath
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    // SSH port number
    private func checksshport(_ port: String) throws -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil {
            return true
        } else {
            throw InputError.notvalidInt
        }
    }

    func sshport(_ port: String) {
        guard inputchangedbyuser == true else { return }
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            configuration?.sshport = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                configuration?.sshport = Int(port)
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension ObserveableParametersRsync: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return NSLocalizedString("Not a valid ", comment: "ssh error") + "..."
        }
    }
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
