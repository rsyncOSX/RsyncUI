//
//  ActorGenerateLogfileforview.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

actor ActorGenerateLogfileforview {
    @concurrent
    nonisolated func generatedata() async -> [LogfileRecords] {
        Logger.process.info("GenerateLogfileforview: generatedata() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let data = await ActorLogToFile(false).readloggfile() {
            return data.map { record in
                LogfileRecords(line: record)
            }
        } else {
            return []
        }
    }
}
