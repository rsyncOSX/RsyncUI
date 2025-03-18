//
//  RsyncCommandView.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 07/01/2021.
//  Copyright © 2021 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct RsyncCommandView: View {
    @Binding var config: SynchronizeConfiguration?
    @Binding var selectedrsynccommand: RsyncCommand

    var body: some View {
        HStack(alignment: .bottom) {
            pickerselectcommand

            Spacer()

            if config != nil {
                showcommand
            }
        }
    }

    var pickerselectcommand: some View {
        Picker("", selection: $selectedrsynccommand) {
            ForEach(RsyncCommand.allCases) { Text($0.description)
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
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            )
    }

    var commandstring: String? {
        if let config {
            return RsyncCommandtoDisplay(display: selectedrsynccommand,
                                         config: config).rsynccommand
        }
        return nil
    }
}
