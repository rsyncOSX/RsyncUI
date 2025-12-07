//
//  CreateHandlers.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/11/2025.
//

import Foundation
import RsyncProcess

@MainActor
struct CreateHandlers {
    func createHandlers(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?) -> Void

    ) -> ProcessHandlers {
        ProcessHandlers(
            processTermination: processTermination,
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath,
            checkLineForError: TrimOutputFromRsync().checkForRsyncError(_:),
            updateProcess: SharedReference.shared.updateprocess,
            propagateError: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkForErrorInRsyncOutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncVersion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment,
            printLine: RsyncOutputCapture.shared.makePrintLinesClosure()
        )
    }
}
