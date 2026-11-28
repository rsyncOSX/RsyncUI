//
//  HiddenConfigurationsTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite("Tasks hidden without rsync 3.x", .tags(.storage), .serialized)
struct HiddenConfigurationsTests {
    private let profile = "HiddenConfigurationsTestsProfile"

    private func config(_ hiddenID: Int, _ task: String) -> SynchronizeConfiguration {
        var config = SynchronizeConfiguration()
        config.hiddenID = hiddenID
        config.task = task
        config.localCatalog = "/Users/test/source/"
        config.offsiteCatalog = "/Users/test/dest/"
        return config
    }

    @Test("Snapshot and syncremote are hidden only without rsync 3.x")
    func hiddenOnlyWithoutVersion3() {
        #expect(HiddenConfigurations.isHidden(task: "snapshot", rsyncversion3: false))
        #expect(HiddenConfigurations.isHidden(task: "syncremote", rsyncversion3: false))
        #expect(HiddenConfigurations.isHidden(task: "synchronize", rsyncversion3: false) == false)
        #expect(HiddenConfigurations.isHidden(task: "snapshot", rsyncversion3: true) == false)
        #expect(HiddenConfigurations.isHidden(task: "syncremote", rsyncversion3: true) == false)
    }

    @Test("Writing the visible list keeps the hidden tasks")
    func mergeKeepsHiddenTasks() {
        let visible = [config(1, "synchronize"), config(3, "synchronize")]
        let hidden = [config(2, "snapshot"), config(4, "syncremote")]
        let merged = HiddenConfigurations.merge(visible, hidden: hidden)
        #expect(merged.map(\.hiddenID) == [1, 3, 2, 4])
    }

    @Test("A hidden task already in the visible list is not written twice")
    func mergeDoesNotDuplicate() {
        let visible = [config(1, "synchronize"), config(2, "snapshot")]
        let hidden = [config(2, "snapshot")]
        #expect(HiddenConfigurations.merge(visible, hidden: hidden).map(\.hiddenID) == [1, 2])
    }

    @Test("Hidden tasks are kept per profile")
    func storedPerProfile() {
        defer {
            HiddenConfigurations.set([], profile: profile)
            HiddenConfigurations.set([], profile: nil)
        }
        HiddenConfigurations.set([config(5, "snapshot")], profile: profile)
        #expect(HiddenConfigurations.hiddenIDs(profile: profile) == [5])
        #expect(HiddenConfigurations.hiddenIDs(profile: nil).isEmpty)
        HiddenConfigurations.set([], profile: profile)
        #expect(HiddenConfigurations.hidden(profile: profile).isEmpty)
    }

    @Test("A new task never reuses the hiddenID of a hidden task")
    func maxHiddenIDIncludesHiddenTasks() {
        defer { HiddenConfigurations.set([], profile: profile) }
        HiddenConfigurations.set([config(7, "snapshot")], profile: profile)
        let update = UpdateConfigurations(profile: profile,
                                          configurations: [config(1, "synchronize"), config(2, "synchronize")])
        #expect(update.maxhiddenID == 7)
    }
}
