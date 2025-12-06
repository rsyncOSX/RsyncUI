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
    func createhandlers(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?) -> Void

    ) -> ProcessHandlers {
        ProcessHandlers(
            processtermination: processTermination,
            filehandler: fileHandler,
            rsyncpath: GetfullpathforRsync().rsyncpath,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkforerrorinrsyncoutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncversion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment,
            printlines: RsyncOutputCapture.shared.makePrintLinesClosure()
        )
    }
}
