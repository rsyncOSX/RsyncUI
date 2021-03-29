//
//  ImageZstackProgressview.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/02/2021.
//

import SwiftUI

struct ImageZstackProgressview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            ProgressView {
                Text(NSLocalizedString("Working", comment: "progressview") + "...")
                    .font(.title2)
            }
        }
        .frame(width: 120, height: 120, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }
}
