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
    var configurations: [Configuration]?
    var datafile = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    init(_ profile: String?, _ configurations: [Configuration]?) {
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
            .decode(type: [DecodeConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                var configurations = [Configuration]()
                for i in 0 ..< data.count {
                    let transformed = TransformConfigfromJSON().transform(data[i])
                    if SharedReference.shared.synctasks.contains(transformed.task) {
                        if validhiddenIDs.contains(transformed.hiddenID) == false {
                            configurations.append(transformed)
                            validhiddenIDs.insert(transformed.hiddenID)
                        }
                    }
                }
                self.configurations = configurations
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}

/*
 TODO: fix fullroot!
 */

