//
//  AddTaskSheetView.swift
//  RsyncUI
//
//  Created by Tim Reichen on 13.07.2026.
//

import SwiftUI

struct AddTaskSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var newdata: ObservableAddConfigurations
    @Binding var selectedconfig: SynchronizeConfiguration?
    @Binding var changesnapshotnum: Bool
    @Binding var stringestimate: String

    var onAdd: () -> Void

        var body: some View {
            VStack {
                Text("Add Task")
                    .font(.title2)

                TaskForm(mode: .add, newdata: $newdata, selectedconfig: $selectedconfig, changesnapshotnum: $changesnapshotnum, stringestimate: $stringestimate)
            }
            .padding()
            .frame(minWidth: 600)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
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
