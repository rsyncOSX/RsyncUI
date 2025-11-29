//
//  WidgetURLstrings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/01/2025.
//

import Foundation

@MainActor
struct WidgetURLstrings: @MainActor Codable {
    var urlstringestimate: String?

    @discardableResult
    init(urletimate: String) {
        urlstringestimate = urletimate
    }
}
