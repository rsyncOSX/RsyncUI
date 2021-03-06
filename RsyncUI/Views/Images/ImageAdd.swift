//
//  ImageAdd.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct ImageAdd: View {
    var body: some View {
        Image(systemName: "text.badge.plus")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
