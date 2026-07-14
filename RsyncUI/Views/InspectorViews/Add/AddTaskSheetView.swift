//
//  AddTaskSheetView.swift
//  RsyncUI
//
//  Created by Tim Reichen on 13.07.2026.
//

import SwiftUI

struct AddTaskSheetView: View {
    @Environment(\.dismiss) var dismiss

    @FocusState.Binding var focusField: AddConfigurationField?
    @State var newdata = ObservableAddConfigurations()

    func loadTrailingSlashPreference() {
        if let value = UserDefaults.standard.value(forKey: "trailingslashoptions") as? String {
            newdata.trailingslashoptions = TrailingSlash(rawValue: value) ?? .add
        }
    }

    func loadRsyncCommandPreference() {
        if let value = UserDefaults.standard.value(forKey: "selectedrsynccommand") as? String {
            newdata.selectedrsynccommand = TypeofTask(rawValue: value) ?? .synchronize
        }
    }

    var onAdd: (ObservableAddConfigurations) -> Void
    var onSubmit: () -> Void

    var body: some View {
        VStack {
            Text("Add Task")
                .font(.title2)

            TaskForm(focusField: $focusField, newdata: $newdata)
                .onSubmit {
                    onSubmit()
                }
                .onAppear {
                    loadTrailingSlashPreference()
                    loadRsyncCommandPreference()
                }
                .padding()
                .frame(minWidth: 600)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            onAdd(newdata)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 600)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            onAdd(newdata)
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
