//
//  ObservableRsyncOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2024.
//

import Observation
import OSLog

@Observable
final class ObservableRsyncOutput {
    var output: [RsyncOutputData]?
}
