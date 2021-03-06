//
//  ImageSettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct ImageSettings: View {
    var body: some View {
        Image(systemName: "gearshape")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
