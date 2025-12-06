//
//  CreateCommandHandlers.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/11/2025.
//

import Foundation
import ProcessCommand

@MainActor
struct CreateCommandHandlers {
    func createcommandhandlers(
        processTermination: @escaping ([String]?, Bool) -> Void

    ) -> ProcessHandlersCommand {
        ProcessHandlersCommand(
            processtermination: processTermination,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            rsyncui: true
        )
    }
}
