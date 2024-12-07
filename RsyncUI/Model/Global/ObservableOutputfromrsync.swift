//
//  ObservableOutputfromrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/05/2024.
//

import SwiftUI

struct RsyncOutputData: Identifiable, Equatable, Hashable {
    let id = UUID()
    var record: String
}

@Observable @MainActor
final class ObservableOutputfromrsync {
    var output: [RsyncOutputData]?
}
