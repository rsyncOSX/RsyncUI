//
//  ImportExportCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ImportExportCommands: Commands {
    @FocusedBinding(\.exporttasks) private var exporttasks
    @FocusedBinding(\.importtasks) private var importtasks

    var body: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.importExport) {
            Menu("Export and import") {
                ExporttasksButton(exporttasks: $exporttasks)
                ImporttasksButton(importtasks: $importtasks)
            }
        }
    }
}

struct ExporttasksButton: View {
    @Binding var exporttasks: Bool?

    var body: some View {
        Button {
            exporttasks = true
        } label: {
            Label("Export", systemImage: "play.fill")
        }
    }
}

struct ImporttasksButton: View {
    @Binding var importtasks: Bool?

    var body: some View {
        Button {
            importtasks = true
        } label: {
            Label("Import", systemImage: "play.fill")
        }
    }
}

struct FocusedExporttasksBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedImporttasksBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var exporttasks: FocusedExporttasksBinding.Value? {
        get { self[FocusedExporttasksBinding.self] }
        set { self[FocusedExporttasksBinding.self] = newValue }
    }

    var importtasks: FocusedImporttasksBinding.Value? {
        get { self[FocusedImporttasksBinding.self] }
        set { self[FocusedImporttasksBinding.self] = newValue }
    }
}
