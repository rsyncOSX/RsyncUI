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

    @Test("The trailing slash is applied to the source folder")
    func trailingSlashOnSource() {
        let model = ObservableAddConfigurations()
        model.localcatalog = "/local"
        model.remotecatalog = "/remote"

        model.selectedrsynccommand = .syncremote
        model.applyTrailingSlashToSource(enabled: true)
        #expect(model.localcatalog == "/local")
        #expect(model.remotecatalog == "/remote/")

        model.selectedrsynccommand = .synchronize
        model.applyTrailingSlashToSource(enabled: true)
        #expect(model.localcatalog == "/local/")
    }

    @Test("Detect unsaved changes")
    func unsavedChanges() {
        var configuration = SynchronizeConfiguration()
        configuration.task = TypeofTask.synchronize.rawValue
        configuration.localCatalog = "/local/"
        configuration.offsiteCatalog = "/remote"

        let model = ObservableAddConfigurations()
        #expect(model.hasUnsavedChanges == false)

        model.updateview(configuration)
        #expect(model.hasUnsavedChanges == false)

        model.backupID = "New ID"
        #expect(model.hasUnsavedChanges)
    }
}
