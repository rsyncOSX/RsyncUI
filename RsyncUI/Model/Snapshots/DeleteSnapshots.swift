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
    }

    func deletesnapshots() {}

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
    func processtermination() {}

    func filehandler() {}
}
