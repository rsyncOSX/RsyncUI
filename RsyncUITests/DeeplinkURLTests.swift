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
@Suite(.serialized, .tags(.deeplink))
struct DeeplinkURLTests {
    @Test("Create estimate-and-synchronize URL with default profile")
    func createURLDefaultProfile() throws {
        let url = try #require(DeeplinkURL().createURLestimateandsynchronize(valueprofile: nil))
        #expect(url.absoluteString.contains("profile=Default"))
    }

    @Test("Create estimate-and-synchronize URL with custom profile")
    func createURLCustomProfile() throws {
        let url = try #require(DeeplinkURL().createURLestimateandsynchronize(valueprofile: "Work"))
        #expect(url.absoluteString.contains("profile=Work"))
    }

    @Test("Validate profile accepts default when nil")
    func validateProfileAllowsNil() {
        let profiles = [ProfilesnamesRecord("Default"), ProfilesnamesRecord("Work")]
        let isValid = DeeplinkURL().validateProfile(nil, profiles)

        #expect(isValid == true)
    }

    @Test("Validate profile accepts known profile")
    func validateProfileAcceptsKnownProfile() {
        let profiles = [ProfilesnamesRecord("Default"), ProfilesnamesRecord("Work")]
        let isValid = DeeplinkURL().validateProfile("Work", profiles)

        #expect(isValid == true)
    }

    @Test("Validate profile rejects unknown profile")
    func validateProfileRejectsUnknownProfile() {
        let profiles = [ProfilesnamesRecord("Default"), ProfilesnamesRecord("Work")]
        let isValid = DeeplinkURL().validateProfile("Personal", profiles)

        #expect(isValid == false)
    }
}
