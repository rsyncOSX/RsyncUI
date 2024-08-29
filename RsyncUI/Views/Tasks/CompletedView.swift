//
//  CompletedView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/05/2024.
//

import SwiftUI

struct CompletedView: View {
    @Binding var path: [Tasks]

    var body: some View {
        MessageView(dismissafter: 1, mytext: NSLocalizedString("Synchronize data is completed", comment: ""))
            .onDisappear {
                path.removeAll()
            }
    }
}
