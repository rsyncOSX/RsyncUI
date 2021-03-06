//
//  ImageProgressview.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/02/2021.
//

import SwiftUI

struct ImageProgressview: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(MyCustomProgressViewStyle())
    }
}

struct MyCustomProgressViewStyle: ProgressViewStyle {
    typealias ProgressViewStyle = ProgressViewStyleConfiguration

    func makeBody(configuration: ProgressViewStyle) -> some View {
        ProgressView(configuration)
            .accentColor(.blue)
            .frame(width: 20, height: 20, alignment: .center)
    }
}
