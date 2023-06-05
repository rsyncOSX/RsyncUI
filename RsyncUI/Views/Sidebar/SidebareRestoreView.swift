//
//  SidebareRestoreView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//

import SwiftUI

struct SidebareRestoreView: View {
    @Binding var selectedprofile: String?

    var body: some View {
        RestoreTableView()
            .padding()
    }
}
