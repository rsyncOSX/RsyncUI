//
//  QuickTaskSourcePathTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@Suite("Quick Task source path")
struct QuickTaskSourcePathTests {
    @Test("Apply the trailing-slash preference")
    func applyTrailingSlashPreference() {
        #expect(QuickTaskSourcePath.applyingTrailingSlash(to: "/source", enabled: true) == "/source/")
        #expect(QuickTaskSourcePath.applyingTrailingSlash(to: "/source/", enabled: true) == "/source/")
        #expect(QuickTaskSourcePath.applyingTrailingSlash(to: "/source///", enabled: false) == "/source")
        #expect(QuickTaskSourcePath.applyingTrailingSlash(to: "/", enabled: false) == "/")
        #expect(QuickTaskSourcePath.applyingTrailingSlash(to: "", enabled: true).isEmpty)
    }
}
