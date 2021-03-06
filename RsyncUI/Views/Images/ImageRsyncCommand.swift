//
//  ImageRsyncCommand.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct ImageRsyncCommand: View {
    var body: some View {
        Image(systemName: "command.circle.fill")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
