//
//  AddTaskSectionHeader.swift
//  RsyncUI
//
//  Created by Codex on 11/05/2026.
//

import SwiftUI

struct AddTaskSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .padding(.top, 4)
    }
}
