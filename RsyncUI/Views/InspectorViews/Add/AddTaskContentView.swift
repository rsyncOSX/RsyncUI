import SwiftUI

struct AddTaskContentView<UpdateButton: View, TrailingSlash: View, SyncID: View, CatalogSection: View, Remote: View, Snapshot: View, SaveURL: View>: View {
    let updateButton: UpdateButton
    let trailingslash: TrailingSlash
    let synchronizeID: SyncID
    let catalogSectionView: CatalogSection
    let remoteuserandserver: Remote
    let snapshotView: Snapshot
    let saveURLSection: SaveURL

    let showSnapshot: Bool

    init(
        @ViewBuilder updateButton: () -> UpdateButton,
        @ViewBuilder trailingslash: () -> TrailingSlash,
        @ViewBuilder synchronizeID: () -> SyncID,
        @ViewBuilder catalogSectionView: () -> CatalogSection,
        @ViewBuilder remoteuserandserver: () -> Remote,
        @ViewBuilder snapshotView: () -> Snapshot,
        @ViewBuilder saveURLSection: () -> SaveURL,
        showSnapshot: Bool
    ) {
        self.updateButton = updateButton()
        self.trailingslash = trailingslash()
        self.synchronizeID = synchronizeID()
        self.catalogSectionView = catalogSectionView()
        self.remoteuserandserver = remoteuserandserver()
        self.snapshotView = snapshotView()
        self.saveURLSection = saveURLSection()
        self.showSnapshot = showSnapshot
    }

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
