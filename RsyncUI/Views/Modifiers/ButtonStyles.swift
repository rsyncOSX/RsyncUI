//
//  ButtonStyles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/03/2021.
//

import SwiftUI

extension Color {
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)

    static let lightStart = Color(red: 60 / 255, green: 160 / 255, blue: 240 / 255)
    static let lightEnd = Color(red: 30 / 255, green: 80 / 255, blue: 120 / 255)
    /*
        static let darkredStart = Color(red: 200 / 255, green: 0 / 255, blue: 0 / 255)
        static let darkredEnd = Color(red: 150 / 255, green: 0 / 255, blue: 0 / 255)

        static let lightredStart = Color(red: 100 / 255, green: 0 / 255, blue: 0 / 255)
        static let lightredEnd = Color(red: 50 / 255, green: 0 / 255, blue: 0 / 255)
     */
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(8)
            .contentShape(Capsule())
            .background(
                ColorfulBackground(isHighlighted: configuration.isPressed, shape: Capsule())
            )
    }
}

/*

 struct TransitionButton: Transition {
     func body(content: Content, phase: TransitionPhase) -> some View {
         content
             .rotationEffect(Angle(degrees: phase.isIdentity ? 360 : 0))
             .scaleEffect(phase.isIdentity ? 1 : 0)
     }
 }

 struct PressedButtonStyle: ButtonStyle {
     let title: String
     let systemImage: String
     let pressedImage: String

     func makeBody(configuration: Configuration) -> some View {
         let imageName = configuration.isPressed ? pressedImage : systemImage
         return Label(title, systemImage: imageName)
             .symbolEffect(.scale.up, isActive: configuration.isPressed)
     }
 }

 struct ColorfulRedBackground<S: Shape>: View {
     var isHighlighted: Bool
     var shape: S

     var body: some View {
         ZStack {
             if isHighlighted {
                 shape
                     .fill(LinearGradient(Color.lightredEnd, Color.lightredStart))
                     .overlay(shape.stroke(LinearGradient(Color.lightredStart, Color.lightredEnd), lineWidth: 2))
                     .shadow(color: Color.darkredStart, radius: 2, x: 1, y: 1)
                     .shadow(color: Color.darkredEnd, radius: 2, x: -1, y: -1)
             } else {
                 shape
                     .fill(LinearGradient(Color.darkredStart, Color.darkredEnd))
                     .overlay(shape.stroke(LinearGradient(Color.lightredStart, Color.lightredEnd), lineWidth: 2))
                     .shadow(color: Color.darkredStart, radius: 2, x: -1, y: -1)
                     .shadow(color: Color.darkredEnd, radius: 2, x: 1, y: 1)
             }
         }
     }
 }

 struct InfoButton: View {
   let action: () -> Void

   init(_ action: @escaping () -> Void) {
     self.action = action
   }

   var body: some View {
     Button("") {
       action()
     }
     .buttonStyle(
       PressedButtonStyle(
         title: "Info",
         systemImage: "info.circle",
         pressedImage: "info.circle.fill")
     )
     .padding()
   }
 }

 struct ColorfulRedButtonStyle: ButtonStyle {
     func makeBody(configuration: Self.Configuration) -> some View {
         configuration.label
             .foregroundColor(.white)
             .padding(8)
             .contentShape(Capsule())
             .background(
                 ColorfulRedBackground(isHighlighted: configuration.isPressed, shape: Capsule())
             )
     }
 }
 */
