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

    static func visibleLogs(
        from store: LogStore?,
        configurations: [SynchronizeConfiguration]?,
        configurationID: SynchronizeConfiguration.ID?,
        filterString: String = ""
    ) -> [Log] {
        let hiddenID = configurations?.hiddenID(for: configurationID) ?? -1
        return visibleLogs(from: store, hiddenID: hiddenID, filterString: filterString)
    }

    static func visibleLogs(
        from store: LogStore?,
        hiddenID: Int,
        filterString: String = ""
    ) -> [Log] {
        let records = mergedLogs(from: store, hiddenID: hiddenID)
        guard filterString.isEmpty == false else { return records }

        return records.filter { record in
            let dateString = record.dateExecuted?.en_date_from_string().long_localized_string_from_date() ?? ""
            let dateMatch = dateString.contains(filterString)
            let resultMatch = (record.resultExecuted?.contains(filterString)) ?? false
            return dateMatch || resultMatch
        }
    }

    static func deletingLogs(
        _ ids: Set<Log.ID>,
        from store: LogStore?
    ) -> LogStore? {
        guard var store else { return nil }

        for index in store.indices {
            store[index].logrecords?.removeAll { record in
                ids.contains(record.id)
            }
        }

        return store
    }

    static func deleteLogs(
        _ ids: Set<Log.ID>,
        profile: String?,
        in store: LogStore?
    ) async -> LogStore? {
        let updatedStore = deletingLogs(ids, from: store)
        await WriteLogRecordsJSON.write(profile, updatedStore)
        return updatedStore
    }
}

private extension LogStoreService {
    static func mergedLogs(
        from store: LogStore?,
        hiddenID: Int
    ) -> [Log] {
        if hiddenID == -1 {
            return sortedLogs(store?.flatMap { $0.logrecords ?? [] } ?? [])
        }

        let taskLogs = store?.first(where: { $0.hiddenID == hiddenID })?.logrecords ?? []
        return sortedLogs(taskLogs)
    }

    static func sortedLogs(_ logs: [Log]) -> [Log] {
        logs.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
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
