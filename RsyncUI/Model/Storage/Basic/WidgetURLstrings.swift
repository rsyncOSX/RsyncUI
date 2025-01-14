//
//  WidgetURLstrings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/01/2025.
//

import Foundation

@MainActor
struct WidgetURLstrings: Codable {
    
    var urlstringestimate: String?
    var urlstringverify: String?
    
    @discardableResult
    init(_ data: DecodeWidgetStrings) {
        urlstringverify = data.urlstringverify
        urlstringestimate = data.urlstringestimate
    }
}
