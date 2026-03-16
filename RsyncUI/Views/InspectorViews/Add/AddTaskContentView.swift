import SwiftUI

struct AddTaskContentView<UpdateButton: View, TrailingSlash: View, SyncID: View, CatalogSection: View, Remote: View, Snapshot: View, SaveURL: View>: View {
    @ViewBuilder let updateButton: UpdateButton
    @ViewBuilder let trailingslash: TrailingSlash
    @ViewBuilder let synchronizeID: SyncID
    @ViewBuilder let catalogSectionView: CatalogSection
    @ViewBuilder let remoteuserandserver: Remote
    @ViewBuilder let snapshotView: Snapshot
    @ViewBuilder let saveURLSection: SaveURL

    let showSnapshot: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                updateButton
                trailingslash
            }

            synchronizeID
            catalogSectionView

            VStack(alignment: .leading) { remoteuserandserver }

            if showSnapshot {
                VStack(alignment: .leading) { snapshotView }
            }

            saveURLSection
        }
        .padding()
    }
}
