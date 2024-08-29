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
        MessageView(dismissafter: 0.5, mytext: "Synchronize data is completed", width: 450)
            .onDisappear {
                path.removeAll()
            }
    }
}
