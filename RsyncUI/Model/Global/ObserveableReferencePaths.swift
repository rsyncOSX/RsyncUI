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
    @Published var pathrsyncosx: String = SharedReference.shared.pathrsyncui ?? ""
    @Published var pathrsyncosxsched: String = SharedReference.shared.pathrsyncschedule ?? ""
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
        $pathrsyncosx
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncosx in
                setandvalidapathrsyncosx(pathtorsyncosx)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $pathrsyncosxsched
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] pathtorsyncosxsched in
                setandvalidapathpathrsyncosxsched(pathtorsyncosxsched)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }
}

extension ObserveableReferencePaths {
    func setandvalidapathrsyncosx(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                isDirty = true
                SharedReference.shared.pathrsyncui = atpath
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    func setandvalidapathpathrsyncosxsched(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                isDirty = true
                SharedReference.shared.pathrsyncschedule = atpath
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
