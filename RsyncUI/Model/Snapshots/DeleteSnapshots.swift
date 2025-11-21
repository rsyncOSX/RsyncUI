//
//  DeleteSnapshots.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/05/2021.
//

import Foundation
import OSLog
import ProcessCommand

@MainActor
final class DeleteSnapshots {
    var localeconfig: SynchronizeConfiguration?
    var snapshotcatalogstodelete: [String]?
    var mysnapshotdata: ObservableSnapshotData?

    private func preparesnapshotcatalogsfordelete(logrecordssnapshot: [LogRecordSnapshot]?) {
        if let uuidsfordelete = mysnapshotdata?.snapshotuuidsfordelete, let logrecordssnapshot {
            snapshotcatalogstodelete = logrecordssnapshot.compactMap { record in
                let snaproot = localeconfig?.offsiteCatalog
                let snapcatalog = record.snapshotCatalog
                let pathfordelete = (snaproot ?? "") + (snapcatalog ?? "").dropFirst(2)
                return (uuidsfordelete.contains(record.id)) ? pathfordelete : nil
            }
        }
        // Set maxnumber and remaining to delete
        mysnapshotdata?.maxnumbertodelete = snapshotcatalogstodelete?.count ?? 0
        mysnapshotdata?.remainingsnapshotstodelete = snapshotcatalogstodelete?.count ?? 0
    }

    func deletesnapshots() {
        guard (snapshotcatalogstodelete?.count ?? 0) > 0 else {
            mysnapshotdata?.inprogressofdelete = false
            return
        }
        if let remotecatalog = snapshotcatalogstodelete?[0] {
            Logger.process.debugmesseageonly("DeleteSnapshots: deleting snapshot catalog \(remotecatalog)")
            snapshotcatalogstodelete?.remove(at: 0)
            if (snapshotcatalogstodelete?.count ?? 0) == 0 {
                snapshotcatalogstodelete = nil
            }
            // Remaining number to delete
            let remaining = snapshotcatalogstodelete?.count ?? 0
            mysnapshotdata?.remainingsnapshotstodelete = (mysnapshotdata?.maxnumbertodelete ?? 0) - remaining
            if let config = localeconfig {
                let handlers = CreateCommandHandlers().createcommandhandlers(
                    processtermination: processtermination)

                let delete = ArgumentsSnapshotDeleteCatalogs(config: config, remotecatalog: remotecatalog)
                let process = ProcessCommand(command: delete.getCommand(),
                                             arguments: delete.getArguments(),
                                             handlers: handlers)
                do {
                    try process.executeProcess()
                } catch let e {
                    let error = e
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            }
        }
    }

    init(config: SynchronizeConfiguration,
         snapshotdata: ObservableSnapshotData,
         logrecordssnapshot: [LogRecordSnapshot]?)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        localeconfig = config
        mysnapshotdata = snapshotdata
        preparesnapshotcatalogsfordelete(logrecordssnapshot: logrecordssnapshot)
    }
}

extension DeleteSnapshots {
    func processtermination(data _: [String]?, _: Bool) {
        deletesnapshots()
    }
}
