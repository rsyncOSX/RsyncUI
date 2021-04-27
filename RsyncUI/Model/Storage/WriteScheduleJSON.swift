//
//  NewWriteScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Combine
import Files
import Foundation

class WriteScheduleJSON: NamesandPaths {
    var subscriptons = Set<AnyCancellable>()

    func writeJSONToPersistentStore(_ data: String?) {
        if var atpath = fullroot {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename ?? "")
                if let data = data {
                    try file.write(data)
                    if SharedReference.shared.menuappisrunning {
                        Notifications().showNotification(SharedReference.shared.reloadstring)
                        DistributedNotificationCenter.default()
                            .postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring),
                                                  object: nil, deliverImmediately: true)
                    }
                }
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    @discardableResult
    init(_ profile: String?, _ schedules: [ConfigurationSchedule]?) {
        super.init(profileorsshrootpath: .profileroot)
        // Set profile and filename ahead of encoding an write
        self.profile = profile
        filename = SharedReference.shared.fileschedulesjson
        schedules.publisher
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                // verifynewversion(result)
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
            })
            .store(in: &subscriptons)
    }
}
