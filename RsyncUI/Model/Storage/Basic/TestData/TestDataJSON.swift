//
//  TestDataJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import Foundation

class TestDataJSON {
    let urlSession = URLSession.shared
    let jsonDecoder = JSONDecoder()
    
    var configurationsJSON: String =
    "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/configurations.json"
    var logrecordsJSON: String =
    "https://raw.githubusercontent.com/rsyncOSX/RsyncUI/master/samplejsondata/ogrecords.json"
    
    var configurations: [Configuration]?
    var logrecords: [LogRecords]?
    
    func getconfigurationsJSON() async throws -> [Configuration]? {
        if let url = URL(string: configurationsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([Configuration].self, from: data)
        } else {
            return nil
        }
    }
    
    func getlogrecordsJSON() async throws -> [LogRecords]? {
        if let url = URL(string: logrecordsJSON) {
            let (data, _) = try await urlSession.data(from: url)
            return try jsonDecoder.decode([LogRecords].self, from: data)
        } else {
            return nil
        }
    }
    
    func getJSONdata() async {
        do {
            if let data = try await getconfigurationsJSON() {
                configurations = data
            }
            
        } catch {
            
        }
        
        do {
            if let data = try await getlogrecordsJSON() {
                logrecords = data
            }
            
        } catch {
            
        }
    }
    
    init() {
        Task {
            await getJSONdata()
        }
    }
}
