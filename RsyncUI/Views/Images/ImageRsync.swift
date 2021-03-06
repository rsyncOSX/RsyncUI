//
//  ImageSidebarRsync.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 27/01/2021.
//

import SwiftUI

struct ImageRsync: View {
    var body: some View {
        Image("rsync")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 48)
            .padding(.bottom, 10)
    }
}
