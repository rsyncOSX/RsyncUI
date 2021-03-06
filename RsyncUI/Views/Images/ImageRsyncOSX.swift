//
//  ImageRsyncOSXView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 27/01/2021.
//

import SwiftUI

struct ImageRsyncOSX: View {
    var body: some View {
        Image("rsyncosx")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 64)
    }
}
