//
//  ExecuteSingleTaskNowShellout.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 30/01/2021.
//
// swiftlint:disable line_length

import Foundation
import ShellOut

final class ExecuteSingleTaskNowShellout: ExecuteSingleTaskNow {
    var error: Bool = false

    func executepretask() throws {
        if let hiddenID = self.hiddenID {
            if let pretask = localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.pretask {
                let task = try shellOut(to: pretask)
                if task.contains("error"), (localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.haltshelltasksonerror ?? 0) == 1 {
                    let outputprocess = OutputProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: pretask containes error, aborting")
                    error = true
                    // _ = Logging(outputprocess, true)
                }
            }
        }
    }

    func executeposttask() throws {
        if let hiddenID = self.hiddenID {
            if let posttask = localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.posttask {
                let task = try shellOut(to: posttask)
                if task.contains("error"), (localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.haltshelltasksonerror ?? 0) == 1 {
                    let outputprocess = OutputProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: posstak containes error")
                    // _ = Logging(outputprocess, true)
                }
            }
        }
    }

    override func executetasknow() {
        guard SharedReference.shared.process == nil else { return }
        if let hiddenID = self.hiddenID {
            // Execute pretask
            if localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.executepretask == 1 {
                do {
                    try executepretask()
                } catch let e {
                    let error = e as? ShellOutError
                    let outputprocess = OutputProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: pretask fault, aborting")
                    outputprocess.addlinefromoutput(str: error?.message ?? "")
                    self.error = true
                    // _ = Logging(outputprocess, true)
                }
            }
            guard error == false else { return }
            outputprocess = OutputProcessRsync()
            if let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcessCmdCombine(arguments: arguments,
                                                 config: localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID),
                                                 processtermination: processtermination,
                                                 filehandler: filehandler)
                command?.executeProcess(outputprocess: outputprocess)
            }
        }
    }

    deinit {
        // Execute posttask
        guard self.error == false else { return }
        if let hiddenID = self.hiddenID {
            if self.localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.executeposttask == 1 {
                do {
                    try self.executeposttask()
                } catch let e {
                    let error = e as? ShellOutError
                    let outputprocess = OutputProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: posttask fault")
                    outputprocess.addlinefromoutput(str: error?.message ?? "")
                    // _ = Logging(outputprocess, true)
                }
            }
        }
    }
}
