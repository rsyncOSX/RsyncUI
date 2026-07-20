//
//  ObservableAddConfigurationsTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@MainActor
@Suite("Edit configuration state")
struct ObservableAddConfigurationsTests {
    @Test("Restore and clear the selected task type")
    func restoreSelectedTaskType() {
        var configuration = SynchronizeConfiguration()
        configuration.task = TypeofTask.syncremote.rawValue

        let model = ObservableAddConfigurations()
        model.updateview(configuration)

        #expect(model.selectedrsynccommand == .syncremote)

        model.updateview(nil)

        #expect(model.selectedrsynccommand == .synchronize)
    }
}
