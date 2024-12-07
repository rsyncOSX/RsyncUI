//
//  PushPullCommandView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import SwiftUI

struct PushPullCommandView: View {
    @Binding var config: SynchronizeConfiguration?
    @Binding var pushpullcommand: PushPullCommand

    var body: some View {
        HStack {
            pickerselectcommand

            Spacer()

            if config != nil {
                showcommand
            }
        }
    }

    var pickerselectcommand: some View {
        Picker("", selection: $pushpullcommand) {
            ForEach(PushPullCommand.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(RadioGroupPickerStyle())
    }

    var showcommand: some View {
        Text(commandstring ?? "")
            .textSelection(.enabled)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue, lineWidth: 4)
            )
    }

    var commandstring: String? {
        if let config {
            return PushPullCommandtoDisplay(display: pushpullcommand,
                                              config: config).command
        }
        return nil
    }
}
