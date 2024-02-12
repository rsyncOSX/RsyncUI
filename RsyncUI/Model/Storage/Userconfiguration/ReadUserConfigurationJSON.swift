//
//  ReadUserConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Combine
import Foundation
import OSLog

class ReadUserConfigurationJSON: NamesandPaths {
    var filenamedatastore = [SharedReference.shared.userconfigjson]
    var subscriptons = Set<AnyCancellable>()

    @discardableResult
    init() {
        super.init(.configurations)
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let path = fullpathmacserial {
                    filename = path + "/" + filenamejson
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: DecodeUserConfiguration.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    // No file, write new file with default values
                    Logger.process.info("ReadUserConfigurationJSON: Creating default file for user configurations")
                    WriteUserConfigurationJSON(UserConfiguration())
                }
            } receiveValue: { [unowned self] data in
                UserConfiguration(data)
                Logger.process.info("ReadUserConfigurationJSON: Reading user configurations from permanent storage")
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
