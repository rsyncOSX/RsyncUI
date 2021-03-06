//
//  ImageLogs.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 30/01/2021.
//

import SwiftUI

struct ImageLogs: View {
    var body: some View {
        Image(systemName: "text.alignleft")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
