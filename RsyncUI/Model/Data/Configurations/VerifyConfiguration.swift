//
//  AddConfiguration.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//
// swiftlint:disable cyclomatic_complexity trailing_comma function_body_length

import Foundation

enum ValidateInputError: LocalizedError {
    case localcatalog
    case offsiteusername
    case notconnected
    case offsiteserver
    case snapshotnum

    var errorDescription: String? {
        switch self {
        case .localcatalog:
            return NSLocalizedString("Either local or remote cannot be empty", comment: "input error") + "..."
        case .offsiteusername:
            return NSLocalizedString("Remote username cannot be empty", comment: "input error") + "..."
        case .notconnected:
            return NSLocalizedString("Not connected, cannot create task", comment: "filesize error") + "..."
        case .offsiteserver:
            return NSLocalizedString("Remote servername cannot be empty", comment: "input error") + "..."
        case .snapshotnum:
            return NSLocalizedString("Snapshotnum must be 1", comment: "filesize error") + "..."
        }
    }
}

struct AppendConfig {
    var newtask: String
    var newlocalCatalog: String
    var newoffsiteCatalog: String
    var newdontaddtrailingbackslash: Bool = false
    // Can be nil
    var newoffsiteUsername: String?
    var newoffsiteServer: String?
    var newbackupID: String?
    // Pre and post tasks
    var newexecutepretask: Bool?
    var newpretask: String?
    var newexecuteposttask: Bool?
    var newposttask: String?
    var newhaltshelltasksonerror: Bool?
    // Use hiddenID for update
    var hiddenID: Int?

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingbackslash: Bool,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?,
         _ executepretask: Bool?,
         _ pretask: String?,
         _ executeposttask: Bool?,
         _ posttask: String?,
         _ haltshelltasksonerror: Bool?)
    {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newdontaddtrailingbackslash = trailingbackslash
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
        newexecutepretask = executepretask
        newpretask = pretask
        newexecuteposttask = executeposttask
        newposttask = posttask
        newhaltshelltasksonerror = haltshelltasksonerror
    }

    init(_ task: String,
         _ localCatalog: String,
         _ offsiteCatalog: String,
         _ trailingbackslash: Bool,
         _ offsiteUsername: String?,
         _ offsiteServer: String?,
         _ backupID: String?,
         _ executepretask: Bool?,
         _ pretask: String?,
         _ executeposttask: Bool?,
         _ posttask: String?,
         _ haltshelltasksonerror: Bool?,
         _ updatedhiddenID: Int)
    {
        newtask = task
        newlocalCatalog = localCatalog
        newoffsiteCatalog = offsiteCatalog
        newdontaddtrailingbackslash = trailingbackslash
        newoffsiteUsername = offsiteUsername
        newoffsiteServer = offsiteServer
        newbackupID = backupID
        newexecutepretask = executepretask
        newpretask = pretask
        newexecuteposttask = executeposttask
        newposttask = posttask
        newhaltshelltasksonerror = haltshelltasksonerror
        hiddenID = updatedhiddenID
    }
}

final class VerifyConfiguration: Connected {
    let archive: String = "--archive"
    let verbose: String = "--verbose"
    let compress: String = "--compress"
    let delete: String = "--delete"
    let eparam: String = "-e"
    let ssh: String = "ssh"

    var outputprocess: OutputfromProcess?

    // Verify parameters for new config.
    func verify(_ data: AppendConfig) -> Configuration? {
        let dict: NSMutableDictionary = [
            DictionaryStrings.task.rawValue: data.newtask,
            DictionaryStrings.backupID.rawValue: data.newbackupID ?? "",
            DictionaryStrings.localCatalog.rawValue: data.newlocalCatalog,
            DictionaryStrings.offsiteCatalog.rawValue: data.newoffsiteCatalog,
            DictionaryStrings.offsiteServer.rawValue: data.newoffsiteServer ?? "",
            DictionaryStrings.offsiteUsername.rawValue: data.newoffsiteUsername ?? "",
            DictionaryStrings.parameter1.rawValue: archive,
            DictionaryStrings.parameter2.rawValue: verbose,
            DictionaryStrings.parameter3.rawValue: compress,
            DictionaryStrings.parameter4.rawValue: delete,
            DictionaryStrings.parameter5.rawValue: eparam,
            DictionaryStrings.parameter6.rawValue: ssh,
            DictionaryStrings.dateRun.rawValue: "",
        ]
        // For updates hiddenID != nil
        if let hiddenID = data.hiddenID {
            dict.setValue(hiddenID, forKey: DictionaryStrings.hiddenID.rawValue)
        }
        if data.newlocalCatalog.hasSuffix("/") == false, data.newdontaddtrailingbackslash == false {
            var catalog = data.newlocalCatalog
            guard catalog.isEmpty == false else { return nil }
            catalog += "/"
            dict.setValue(catalog, forKey: DictionaryStrings.localCatalog.rawValue)
        }
        if data.newoffsiteCatalog.hasSuffix("/") == false, data.newdontaddtrailingbackslash == false {
            var catalog = data.newoffsiteCatalog
            guard catalog.isEmpty == false else { return nil }
            catalog += "/"
            dict.setValue(catalog, forKey: DictionaryStrings.offsiteCatalog.rawValue)
        }
        if data.newtask == SharedReference.shared.snapshot {
            dict.setValue(SharedReference.shared.snapshot, forKey: DictionaryStrings.task.rawValue)
            dict.setValue(1, forKey: DictionaryStrings.snapshotnum.rawValue)
        } else if data.newtask == SharedReference.shared.syncremote {
            dict.setValue(SharedReference.shared.syncremote, forKey: DictionaryStrings.task.rawValue)
        }
        // Validate input and connection if snapshot task
        let newconfig = Configuration(dictionary: dict)
        do {
            let validated = try validateinput(config: newconfig)
            guard validated == true else { return nil }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
            return nil
        }
        // If validated and snapshottask create remote snapshotcatalog
        // Must be connected to create base remote snapshot catalog
        if data.newtask == SharedReference.shared.snapshot {
            outputprocess = OutputfromProcess()
            // If connected create base remote snapshotcatalog
            snapshotcreateremotecatalog(dict: dict, outputprocess: outputprocess)
        }
        // Add pre and post task if set
        // Pre task
        if data.newpretask?.isEmpty == false {
            if data.newexecutepretask == true {
                dict.setObject(1, forKey: DictionaryStrings.executepretask.rawValue as NSCopying)
            } else {
                dict.setObject(0, forKey: DictionaryStrings.executepretask.rawValue as NSCopying)
            }
            dict.setObject(data.newpretask ?? "", forKey: DictionaryStrings.pretask.rawValue as NSCopying)
        } else {
            dict.setObject(0, forKey: DictionaryStrings.executepretask.rawValue as NSCopying)
        }
        // Post task
        if data.newposttask?.isEmpty == false {
            if data.newexecuteposttask == true {
                dict.setObject(1, forKey: DictionaryStrings.executeposttask.rawValue as NSCopying)
            } else {
                dict.setObject(0, forKey: DictionaryStrings.executeposttask.rawValue as NSCopying)
            }
            dict.setObject(data.newposttask ?? "", forKey: DictionaryStrings.posttask.rawValue as NSCopying)
        } else {
            dict.setObject(0, forKey: DictionaryStrings.executeposttask.rawValue as NSCopying)
        }
        // Halt pretask on error in posttask
        if data.newhaltshelltasksonerror == true {
            dict.setObject(1, forKey: DictionaryStrings.haltshelltasksonerror.rawValue as NSCopying)
        } else {
            dict.setObject(0, forKey: DictionaryStrings.haltshelltasksonerror.rawValue as NSCopying)
        }
        // Return a new configuration to be appended
        return Configuration(dictionary: dict)
    }

    // Create remote snapshot catalog
    private func snapshotcreateremotecatalog(dict: NSDictionary, outputprocess: OutputfromProcess?) {
        let config = Configuration(dictionary: dict)
        guard config.offsiteServer.isEmpty == false else { return }
        let args = SnapshotCreateCatalogArguments(config: config)
        let updatecurrent = OtherProcess(command: args.getCommand(),
                                         arguments: args.getArguments(),
                                         processtermination: processtermination,
                                         filehandler: filehandler)
        updatecurrent.executeProcess(outputprocess: outputprocess)
    }

    // Validate input, throws errors
    private func validateinput(config: Configuration) throws -> Bool {
        guard config.localCatalog.isEmpty == false,
              config.offsiteCatalog.isEmpty == false
        else {
            throw ValidateInputError.localcatalog
        }
        if config.offsiteServer.isEmpty == false {
            guard config.offsiteUsername.isEmpty == false else {
                throw ValidateInputError.offsiteusername
            }
        }
        if config.offsiteUsername.isEmpty == false {
            guard config.offsiteServer.isEmpty == false else {
                throw ValidateInputError.offsiteserver
            }
        }
        if config.task == SharedReference.shared.snapshot {
            guard config.snapshotnum == 1 else {
                throw ValidateInputError.snapshotnum
            }
            // also check if connected because creating base remote catalog if remote server
            // must be connected to create remote base catalog
            guard connected(server: config.offsiteServer) else {
                throw ValidateInputError.notconnected
            }
        }
        if config.task == SharedReference.shared.syncremote {
            guard config.offsiteServer.isEmpty == false, config.offsiteUsername.isEmpty == false else {
                throw ValidateInputError.offsiteusername
            }
        }
        return true
    }

    deinit {
        // print("deinit VerifyConfiguration")
    }
}

extension VerifyConfiguration {
    func processtermination() {}

    func filehandler() {}
}

extension VerifyConfiguration: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
