//
//  ImageSingletask.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 30/01/2021.
//

import SwiftUI

struct ImageSingletask: View {
    var body: some View {
        Image(systemName: "arrowshape.turn.up.backward.fill")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
