//
//  DecodeWidgetStrings.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/01/2025.
//
// Library/Containers/no.blogspot.RsyncUI.RsyncUIWidgetEstimate/Data/Documents/
// Library/Containers/no.blogspot.RsyncUI.RsyncUIWidgetVerify/Data/Documents/

struct DecodeWidgetStrings: Codable {
    let urlstringestimate: String?
    let urlstringverify: String?

    enum CodingKeys: String, CodingKey {
        case urlstringestimate
        case urlstringverify
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        urlstringestimate = try values.decodeIfPresent(String.self, forKey: .urlstringestimate)
        urlstringverify = try values.decodeIfPresent(String.self, forKey: .urlstringverify)
    }
}
