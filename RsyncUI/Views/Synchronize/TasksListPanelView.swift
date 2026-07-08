import SwiftUI

struct TasksListPanelView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var doubleclick: Bool
    @Binding var progress: Double

    let progressdetails: ProgressDetails
    let max: Double
    let onSelectedUuidsChange: () -> Void
    let onEstimatedListChange: () -> Void

    var body: some View {
        ListofTasksMainView(
            rsyncUIdata: rsyncUIdata,
            selecteduuids: $selecteduuids,
            doubleclick: $doubleclick,
            progress: $progress,
            progressdetails: progressdetails,
            max: max
        )
        .frame(maxWidth: .infinity)
        .onChange(of: selecteduuids) {
            onSelectedUuidsChange()
        }
        .onChange(of: progressdetails.estimatedlist) {
            onEstimatedListChange()
        }
    }
}
