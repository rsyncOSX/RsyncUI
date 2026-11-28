import Foundation
@testable import RsyncUI
import SwiftUI
import Testing

@MainActor
@Test func previewMustCoverTheEntireRunScope() {
    let a = UUID()
    let b = UUID()
    #expect(!TasksView.hasPreview(for: [b], estimatedIDs: [a]))
    #expect(!TasksView.hasPreview(for: [a, b], estimatedIDs: [a]))
    #expect(!TasksView.hasPreview(for: [], estimatedIDs: [a]))
    #expect(TasksView.hasPreview(for: [b], estimatedIDs: [a, b]))
    #expect(TasksView.hasPreview(for: [a, b], estimatedIDs: [a, b]))
}

@MainActor
@Test func incompleteStatisticsCannotAuthorizeSynchronization() {
    var record = RemoteDataNumbers(stringoutputfromrsync: nil, config: nil)
    #expect(!record.hasUsableStatistics)
    record.stats = "0 files : 0.00 MB in 0.00 seconds"
    record.filestransferred = "No stats"
    #expect(!record.hasUsableStatistics)
    record.filestransferred = "0"
    #expect(record.hasUsableStatistics)
}

@MainActor
@Test func externalCompletionRequiresStatisticsForEveryRequestedTask() {
    var first = RemoteDataNumbers(stringoutputfromrsync: nil, config: nil)
    first.stats = "0 files"
    first.filestransferred = "0"
    var second = first
    second.id = UUID()
    let scope: Set<UUID> = [first.id, second.id]
    #expect(Estimate.hasCompletePreview([first, second], for: scope))
    #expect(!Estimate.hasCompletePreview([], for: []))
    #expect(!Estimate.hasCompletePreview([first], for: scope))
    #expect(!Estimate.hasCompletePreview([first, first], for: scope))
    second.filestransferred = "No stats"
    #expect(!Estimate.hasCompletePreview([first, second], for: scope))
}

@MainActor
@Test(arguments: [nil, "Work"] as [String?])
func singleTaskPreviewRecordsItsProfile(profile: String?) {
    let progressdetails = ProgressDetails()
    let configuration = SynchronizeConfiguration()
    let view = OneTaskDetailsView(progressdetails: progressdetails,
                                  selecteduuids: [configuration.id],
                                  configurations: [configuration],
                                  profile: profile)
    view.processTermination(stringoutputfromrsync: nil, hiddenID: configuration.hiddenID)
    #expect(progressdetails.profile == profile)
    #expect(progressdetails.estimatedlist?.map(\.id) == [configuration.id])
}

@MainActor
@Test func estimatedRunExcludesUnknownUnchangedAndOutOfScopeTasks() {
    func record(files: String, changed: Bool) -> RemoteDataNumbers {
        var record = RemoteDataNumbers(stringoutputfromrsync: nil, config: nil)
        record.stats = "stats"
        record.filestransferred = files
        record.datatosynchronize = changed
        return record
    }
    let changed = record(files: "1", changed: true)
    let unchanged = record(files: "0", changed: false)
    let unknown = record(files: "No stats", changed: true)
    let outOfScope = record(files: "1", changed: true)
    let scope: Set<UUID> = [changed.id, unchanged.id, unknown.id]
    let estimates = [changed, unchanged, unknown, outOfScope]
    #expect(TasksView.estimatedRunScope(for: scope, estimates: estimates) == [changed.id])
    #expect(TasksView.estimatedRunScope(for: [], estimates: estimates).isEmpty)
}

@MainActor
@Test func failedUnestimatedRunClearsInProgressFlag() {
    let data = RsyncUIconfigurations()
    data.executetasksinprogress = true
    let view = ExecuteNoEstTasksView(rsyncUIdata: data,
                                     selecteduuids: .constant([]),
                                     executetaskpath: .constant([]))
    view.updateConfigurations([], outcome: .failure)
    #expect(!data.executetasksinprogress)
}
