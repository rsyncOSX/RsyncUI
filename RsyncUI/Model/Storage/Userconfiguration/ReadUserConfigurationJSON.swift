//
//  ReadUserConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Combine
import Foundation

class ReadUserConfigurationJSON: NamesandPaths {
    var filenamedatastore = [SharedReference.shared.userconfigjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

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
                    // print("The publisher finished normally.")
                    return
                case .failure:
                    // No file, write new file with default values
                    WriteUserConfigurationJSON(UserConfiguration(false))
                }
            } receiveValue: { [unowned self] data in
                UserConfiguration(data)
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
