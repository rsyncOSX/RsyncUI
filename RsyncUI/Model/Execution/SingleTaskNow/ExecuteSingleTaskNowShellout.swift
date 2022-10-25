//
//  ExecuteSingleTaskNowShellout.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 30/01/2021.
//
// swiftlint:disable line_length

import Foundation

final class ExecuteSingleTaskNowShellout: ExecuteSingleTaskNow {
    var error: Bool = false

    func executepretask() throws {
        if let hiddenID = hiddenID {
            if let pretask = localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.pretask {
                let task = try shellOut(to: pretask)
                if task.contains("error"), (localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.haltshelltasksonerror ?? 0) == 1 {
                    let outputprocess = OutputfromProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: pretask containes error, aborting")
                    error = true
                }
            }
        }
    }

    func executeposttask() throws {
        if let hiddenID = hiddenID {
            if let posttask = localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.posttask {
                let task = try shellOut(to: posttask)
                if task.contains("error"), (localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.haltshelltasksonerror ?? 0) == 1 {
                    let outputprocess = OutputfromProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: posstak containes error")
                }
            }
        }
    }

    @MainActor
    override func executetasknow() async {
        guard SharedReference.shared.process == nil else { return }
        if let hiddenID = hiddenID {
            // Execute pretask
            if localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID)?.executepretask == 1 {
                do {
                    try executepretask()
                } catch let e {
                    let error = e as? ShellOutError
                    let outputprocess = OutputfromProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: pretask fault, aborting")
                    outputprocess.addlinefromoutput(str: error?.message ?? "")
                    self.error = true
                }
            }
            guard error == false else { return }
            if let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: hiddenID, argtype: .arg) {
                command = RsyncProcessAsync(arguments: arguments,
                                            config: localconfigurationsSwiftUI?.getconfiguration(hiddenID: hiddenID),
                                            processtermination: processtermination)
                await command?.executeProcess()
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
                    let outputprocess = OutputfromProcess()
                    outputprocess.addlinefromoutput(str: "ShellOut: posttask fault")
                    outputprocess.addlinefromoutput(str: error?.message ?? "")
                }
            }
        }
    }
}
