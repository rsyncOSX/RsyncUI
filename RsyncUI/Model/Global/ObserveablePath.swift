//
//  ObserveableReferencePaths.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Combine
import Foundation

final class ObserveablePath: ObservableObject {
    // Environment
    @Published var environment: String = SharedReference.shared.environment ?? ""
    @Published var environmentvalue: String = SharedReference.shared.environmentvalue ?? ""
    // Paths for apps
    @Published var pathrsyncui: String = SharedReference.shared.pathrsyncui ?? ""
    @Published var pathrsyncschedule: String = SharedReference.shared.pathrsyncschedule ?? ""

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $environment
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { environment in
                SharedReference.shared.environment = environment
            }.store(in: &subscriptions)
        $environmentvalue
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { environmentvalue in
                SharedReference.shared.environmentvalue = environmentvalue
            }.store(in: &subscriptions)
        $pathrsyncui
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncui in
                setandvalidapathrsyncui(pathtorsyncui)
            }.store(in: &subscriptions)
        $pathrsyncschedule
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncschedule in
                setandvalidapathpathrsyncschedule(pathtorsyncschedule)
            }.store(in: &subscriptions)
    }
}

extension ObserveablePath {
    func setandvalidapathrsyncui(_ atpath: String) {
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                if atpath.hasSuffix("/") == false {
                    SharedReference.shared.pathrsyncui = atpath + "/"
                    SharedReference.shared.pathrsyncschedule = atpath + "/"
                } else {
                    SharedReference.shared.pathrsyncui = atpath
                    SharedReference.shared.pathrsyncschedule = atpath
                }
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func setandvalidapathpathrsyncschedule(_ atpath: String) {
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                if atpath.hasSuffix("/") == false {
                    SharedReference.shared.pathrsyncui = atpath + "/"
                    SharedReference.shared.pathrsyncschedule = atpath + "/"
                } else {
                    SharedReference.shared.pathrsyncschedule = atpath
                    SharedReference.shared.pathrsyncui = atpath
                }
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }
}

extension ObserveablePath: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
