//
//  LogStoreService.swift
//  RsyncUI
//

import Foundation

typealias LogStore = [LogRecords]

enum LogStoreService {
    static func loadStore(
        profile: String?,
        configurations: [SynchronizeConfiguration]?
    ) async -> LogStore {
        let validHiddenIDs = configurations?.hiddenIDs ?? []
        return await ActorReadLogRecords().readjsonfilelogrecords(profile, validHiddenIDs) ?? []
    }
}

extension Collection<SynchronizeConfiguration> {
    var hiddenIDs: Set<Int> {
        Set(map(\.hiddenID))
    }

    func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int? {
        first(where: { $0.id == configurationID })?.hiddenID
    }

    func backupID(for configurationID: SynchronizeConfiguration.ID?) -> String? {
        first(where: { $0.id == configurationID })?.backupID
    }
}
