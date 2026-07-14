//
//  AddTaskSheetView.swift
//  RsyncUI
//
//  Created by Tim Reichen on 13.07.2026.
//

import SwiftUI

struct AddTaskSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var newdata = ObservableAddConfigurations()

    var onAdd: (ObservableAddConfigurations) -> Void

        var body: some View {
            VStack {
                Text("Add Task")
                    .font(.title2)

                TaskForm(newdata: $newdata)
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
