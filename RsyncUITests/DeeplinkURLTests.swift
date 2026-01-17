//
//  DeeplinkURLTests.swift
//  RsyncUITests
//
//  Created by Thomas Evensen on 18/12/2025.
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite("Deeplink URL Tests", .serialized)
struct DeeplinkURLTests {
    @Test("Create estimate-and-synchronize URL with default profile")
    func createURLDefaultProfile() async {
        let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: nil)
        #expect(url != nil)
        if let unwrappedURL = url {
            #expect(unwrappedURL.absoluteString.contains("profile=Default"))
        }
    }

    @Test("Create estimate-and-synchronize URL with custom profile")
    func createURLCustomProfile() async {
        let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: "Work")
        #expect(url != nil)
        if let unwrappedURL = url {
            #expect(unwrappedURL.absoluteString.contains("profile=Work"))
        }
    }
}
