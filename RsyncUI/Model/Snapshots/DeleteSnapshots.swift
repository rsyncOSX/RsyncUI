//
//  DeleteSnapshots.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/05/2021.
//

import Foundation

final class DeleteSnapshots {
    var localeconfig: Configuration?
    var outputprocess: OutputfromProcess?
    var snapshotcatalogstodelete: [String]?
    var mysnapshotdata: SnapshotData?

    private func preparesnapshotcatalogsfordelete(logrecordssnapshot: [Logrecordsschedules]?) {
        if snapshotcatalogstodelete == nil { snapshotcatalogstodelete = [] }
        if let uuidsfordelete = mysnapshotdata?.uuidstodelete {
            for i in 0 ..< ((logrecordssnapshot?.count ?? 0) - 1) {
                if let id = logrecordssnapshot?[i].id {
                    if uuidsfordelete.contains(id) {
                        let snaproot = localeconfig?.offsiteCatalog
                        let snapcatalog = logrecordssnapshot?[i].snapshotCatalog
                        snapshotcatalogstodelete?.append((snaproot ?? "") + (snapcatalog ?? "").dropFirst(2))
                    }
                }
            }
        }
        // Set maxnumber and remaining to delete
        mysnapshotdata?.maxnumbertodelete = snapshotcatalogstodelete?.count ?? 0
        mysnapshotdata?.progressindelete = snapshotcatalogstodelete?.count ?? 0
    }

    func deletesnapshots() {
        guard (snapshotcatalogstodelete?.count ?? 0) > 0 else {
            mysnapshotdata?.inprogressofdelete = false
            return
        }
        if let remotecatalog = snapshotcatalogstodelete?[0] {
            snapshotcatalogstodelete?.remove(at: 0)
            if (snapshotcatalogstodelete?.count ?? 0) == 0 {
                snapshotcatalogstodelete = nil
            }
            // Remaining number to delete
            let remaining = snapshotcatalogstodelete?.count ?? 0
            mysnapshotdata?.progressindelete = (mysnapshotdata?.maxnumbertodelete ?? 0) - remaining
            if let config = localeconfig {
                let arguments = SnapshotDeleteCatalogsArguments(config: config, remotecatalog: remotecatalog)
                let command = OtherProcess(command: arguments.getCommand(),
                                           arguments: arguments.getArguments(),
                                           processtermination: processtermination,
                                           filehandler: filehandler)
                command.executeProcess(outputprocess: nil)
            }
        }
    }

    init(config: Configuration,
         configurationsSwiftUI _: ConfigurationsSwiftUI?,
         schedulesSwiftUI _: SchedulesSwiftUI?,
         snapshotdata: SnapshotData,
         logrecordssnapshot: [Logrecordsschedules]?)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        localeconfig = config
        mysnapshotdata = snapshotdata
        preparesnapshotcatalogsfordelete(logrecordssnapshot: logrecordssnapshot)
    }

    deinit {
        // print("deinit Snapshotlogsandcatalogs")
    }
}

extension DeleteSnapshots {
    func processtermination() {
        deletesnapshots()
    }

    func filehandler() {}
}
