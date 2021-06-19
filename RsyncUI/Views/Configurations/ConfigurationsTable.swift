//
//  ConfigurationsTable.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/06/2021.
//

import SwiftUI

struct ConfigurationsTable: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @State private var selection = Set<Configuration.ID>()
    @State var searchText: String = ""
    @State var sortOrder: [KeyPathComparator<Configuration>] = [
        .init(\.dateRun, order: SortOrder.forward),
    ]

    var body: some View {
        VStack {
            table
        }
        .searchable(text: $searchText)
        .toolbar {
            Button(action: sometablefunc) {
                Label("Add", systemImage: "plus")
            }
        }
    }

    var table: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Task", value: \.task)
            TableColumn("ID", value: \.backupID)
            TableColumn("Local catalog", value: \.localCatalog)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
            TableColumn("Remote username", value: \.offsiteUsername)
            TableColumn("Remote server", value: \.offsiteServer)
            TableColumn("Date run", value: \.dateRun!)
            TableColumn("Days since last", value: \.dayssincelastbackup!)
        } rows: {
            ForEach(configurationssorted) { configuration in
                TableRow(configuration)
            }
        }
    }

    var configurationssorted: [Configuration] {
        if let configurations = rsyncUIdata.configurations {
            let sorted = configurations.sorted { conf1, conf2 in
                if let days1 = conf1.dateRun?.en_us_date_from_string(),
                   let days2 = conf2.dateRun?.en_us_date_from_string()
                {
                    if days1 > days2 {
                        return true
                    } else {
                        return false
                    }
                }
                return false
            }
            return sorted
        }
        return []
    }
}

extension ConfigurationsTable {
    func sometablefunc() {}
}
