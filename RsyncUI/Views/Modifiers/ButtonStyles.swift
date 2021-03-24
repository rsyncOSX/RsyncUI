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
            .background(configuration.isPressed ? Color.blue.opacity(0.5) : Color.blue)
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

struct BlueCircleButtonStyle: ButtonStyle {
    typealias ButtonConfiguration = ButtonStyleConfiguration

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .modifier(MakeSquareBounds())
            .background(Circle().fill(Color.blue))
    }
}

struct MakeSquareBounds: ViewModifier {
    @State var size: CGFloat = 25
    func body(content: Content) -> some View {
        let c = ZStack {
            content.alignmentGuide(HorizontalAlignment.center) { (vd) -> CGFloat in
                DispatchQueue.main.async {
                    self.size = max(vd.height, vd.width)
                }
                return vd[HorizontalAlignment.center]
            }
        }
        return c.frame(width: size, height: size)
    }
}
