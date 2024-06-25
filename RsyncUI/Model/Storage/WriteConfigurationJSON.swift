//
//  WriteConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length non_optional_string_data_conversion

import Combine
import Foundation
import OSLog

@MainActor
class WriteConfigurationJSON {
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filename = SharedReference.shared.fileconfigurationsjson
    var profile: String?
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonString: String?) {
        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile = profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                configurationfileURL = tempURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)

            } else {
                configurationfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)
            }
            if let dataString = jsonString, let configurationfileURL = configurationfileURL {
                if let configurationdata = dataString.data(using: .utf8) {
                    do {
                        try configurationdata.write(to: configurationfileURL)
                        let myprofile = profile
                        Logger.process.info("WriteConfigurationJSON - \(myprofile ?? "default profile", privacy: .public): write configurations to permanent storage")
                    } catch let e {
                        let error = e
                        path.propogateerror(error: error)
                    }
                }
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) {
        SharedReference.shared.firsttime = false
        if profile == SharedReference.shared.defaultprofile {
            self.profile = nil
        } else {
            self.profile = profile
        }
        configurations.publisher
            .map { configurations -> [DecodeConfiguration] in
                var data = [DecodeConfiguration]()
                for i in 0 ..< configurations.count {
                    data.append(DecodeConfiguration(configurations[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.path.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonString: jsonfile)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}

// swiftlint:enable line_length non_optional_string_data_conversion
