//
//  ExportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ExportView: View {
    @Binding var focusexport: Bool
    var body: some View {
        Button {
            focusexport = false
        } label: {
            Image(systemName: "return")
                .foregroundColor(Color(.blue))
        }
    }
}
