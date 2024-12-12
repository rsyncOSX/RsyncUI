//
//  PushPullCommandView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import SwiftUI

struct PushPullCommandView: View {
    @Binding var pushpullcommand: PushPullCommand

    let config: SynchronizeConfiguration

    var body: some View {
        HStack {
            pickerselectcommand

            Spacer()

            showcommand
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
        PushPullCommandtoDisplay(display: pushpullcommand,
                                 config: config).command
    }
}
