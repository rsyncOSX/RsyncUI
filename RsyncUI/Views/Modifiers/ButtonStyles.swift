//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

struct HelpButtonStyle: ButtonStyle {
    let redorwhitebutton: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(redorwhitebutton ? .red : .blue)
            .contentShape(Capsule())
    }
}
