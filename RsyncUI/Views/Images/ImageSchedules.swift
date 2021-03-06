//
//  ImageSchedules.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/02/2021.
//

import SwiftUI

struct ImageSchedules: View {
    var body: some View {
        Image(systemName: "calendar.badge.clock")
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 32)
    }
}
