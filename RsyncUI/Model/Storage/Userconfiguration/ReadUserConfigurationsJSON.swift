//
//  ReadUserConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Combine
import Foundation

class ReadUserConfigurationsJSON: NamesandPaths {
    var userconfiguration = UserConfiguration()
    var filenamedatastore = [SharedReference.shared.userconfigjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    init(_: String?) {
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
            .decode(type: [DecodeUserConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            } receiveValue: { [unowned self] data in
                if data.count == 1 {
                    self.userconfiguration = UserConfiguration(data[0])
                }
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
