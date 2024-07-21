//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ImportView: View {
    @Binding var focusimport: Bool
    var body: some View {
        Button {
            focusimport = false
        } label: {
            Image(systemName: "return")
                .foregroundColor(Color(.blue))
        }
    }
}
