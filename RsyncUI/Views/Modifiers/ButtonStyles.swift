//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI
/*
 struct PrimaryButtonStyle: ButtonStyle {
     func makeBody(configuration: Self.Configuration) -> some View {
         configuration.label
             .padding(8)
             .background(configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor)
             .foregroundColor(.white)
             .buttonBorderShape(.roundedRectangle)
             .clipShape(Capsule())
             .onHover { hover in
                 hover ? NSCursor.pointingHand.push() : NSCursor.pop()
             }
     }
 }

 struct AbortButtonStyle: ButtonStyle {
     func makeBody(configuration: Self.Configuration) -> some View {
         configuration.label
             .padding(8)
             .background(configuration.isPressed ? Color.red.opacity(0.5) : Color.red)
             .foregroundColor(.white)
             .buttonBorderShape(.roundedRectangle)
             .clipShape(Capsule())
             .onHover { hover in
                 hover ? NSCursor.pointingHand.push() : NSCursor.pop()
             }
     }
 }
 */
extension Color {
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255)

    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)

    static let lightStart = Color(red: 60 / 255, green: 160 / 255, blue: 240 / 255)
    static let lightEnd = Color(red: 30 / 255, green: 80 / 255, blue: 120 / 255)
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct ColorfulBackground<S: Shape>: View {
    var isHighlighted: Bool
    var shape: S

    var body: some View {
        ZStack {
            if isHighlighted {
                shape
                    .fill(LinearGradient(Color.lightEnd, Color.lightStart))
                    .overlay(shape.stroke(LinearGradient(Color.lightStart, Color.lightEnd), lineWidth: 2))
                    .shadow(color: Color.darkStart, radius: 2, x: 1, y: 1)
                    .shadow(color: Color.darkEnd, radius: 2, x: -1, y: -1)
            } else {
                shape
                    .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                    .overlay(shape.stroke(LinearGradient(Color.lightStart, Color.lightEnd), lineWidth: 2))
                    .shadow(color: Color.darkStart, radius: 2, x: -1, y: -1)
                    .shadow(color: Color.darkEnd, radius: 2, x: 1, y: 1)
            }
        }
    }
}

struct ColorfulButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(8)
            .contentShape(Capsule())
            .background(
                ColorfulBackground(isHighlighted: configuration.isPressed, shape: Capsule())
            )
    }
}

struct ColorfulRedButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.red)
            .padding(8)
            .contentShape(Capsule())
            .background(
                ColorfulBackground(isHighlighted: configuration.isPressed, shape: Capsule())
            )
    }
}
