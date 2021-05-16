//
//  ReadUserConfigurationPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/05/2021.
//

import Combine
import Foundation

final class ReadUserConfigurationPLIST: NamesandPaths {
    var filenamedatastore = [SharedReference.shared.userconfigplist]
    var subscriptons = Set<AnyCancellable>()

    init() {
        super.init(profileorsshrootpath: .profileroot)
        filenamedatastore.publisher
            .compactMap { userconfig -> URL? in
                var filename: String = ""
                filename = (fullroot ?? "") + userconfig
                return URL(fileURLWithPath: filename)
            }
            /*
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            */
            .tryMap{ url -> NSDictionary in
                try (NSDictionary(contentsOf: url) ?? NSDictionary())
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] data in
                _ = Userconfiguration(data)
            }).store(in: &subscriptons)
    }
}
