//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//
// swiftlint:disable multiple_closures_with_trailing_closure

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
        NSLocalizedString("Search", comment: "SearchbarView") + "..."
    }
}
