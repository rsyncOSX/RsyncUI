//
//  WriteConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Files
import Foundation

class WriteConfigurationJSONNEW: NamesandPaths {
    var datafile = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _: [Configuration]?) {
        super.init(profileorsshrootpath: .profileroot)
        self.profile = profile
        datafile.publisher
            .compactMap { filenamejson -> URL? in
                var filename: String = ""
                if let profile = profile {
                    filename = fullroot! + "/" + profile + "/" + filenamejson
                } else {
                    filename = fullroot! + "/" + filenamejson
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [CodableConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                print(data)
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}

/*
 TODO: fix fullroot!
 */
