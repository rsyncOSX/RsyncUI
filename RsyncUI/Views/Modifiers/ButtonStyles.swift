//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: ButtonConfiguration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct AbortButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: ButtonConfiguration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.red.opacity(0.5) : Color.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}
