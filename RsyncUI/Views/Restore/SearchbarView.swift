//
//  SearchbarView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/06/2021.
//

import SwiftUI

struct SearchbarView: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(searchlabel, text: $text)
            Button(action: {
                text = ""
            }) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary).opacity(text == "" ? 0 : 1)
            }
        }
        .padding(7)
        .padding(.horizontal, 25)
        .cornerRadius(8)
    }

    var searchlabel: String {
        "Search"
    }
}
