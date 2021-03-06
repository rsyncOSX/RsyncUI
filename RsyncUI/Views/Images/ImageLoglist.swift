//
//  ImageLoglist.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 02/02/2021.
//

import SwiftUI

struct ImageLoglist: View {
    var body: some View {
        Image("rsyncosx")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 48)
    }
}
