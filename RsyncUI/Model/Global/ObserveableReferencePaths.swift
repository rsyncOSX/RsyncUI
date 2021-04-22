//
//  ObserveableReferencePaths.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Combine
import Foundation

final class ObserveableReferencePaths: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Environment
    @Published var environment: String = SharedReference.shared.environment ?? ""
    @Published var environmentvalue: String = SharedReference.shared.environmentvalue ?? ""
    // Paths for apps
    @Published var pathrsyncui: String = SharedReference.shared.pathrsyncui ?? ""
    @Published var pathrsyncschedule: String = SharedReference.shared.pathrsyncschedule ?? ""
    @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $environment
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] environment in
                SharedReference.shared.environment = environment
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $environmentvalue
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] environmentvalue in
                SharedReference.shared.environmentvalue = environmentvalue
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncui
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncui in
                setandvalidapathrsyncui(pathtorsyncui)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncschedule
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncschedule in
                setandvalidapathpathrsyncschedule(pathtorsyncschedule)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }
}

extension ObserveableReferencePaths {
    func setandvalidapathrsyncui(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                isDirty = true
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
            self.propogateerror(error: error)
        }
    }

    func setandvalidapathpathrsyncschedule(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                isDirty = true
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
            self.propogateerror(error: error)
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }
}

extension ObserveableReferencePaths: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
