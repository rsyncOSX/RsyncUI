//
//  OutputFromMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/02/2021.
//

import Foundation

final class OutputFromMultipleTasks: ObservableObject {
    private var output: [RemoteinfonumbersOnetask]?

    func setoutput(output: [RemoteinfonumbersOnetask]?) {
        self.output = output
    }

    func getoutput() -> [RemoteinfonumbersOnetask]? {
        return output
    }

    func resetoutput() {
        output = nil
    }
}
