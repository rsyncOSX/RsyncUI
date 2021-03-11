//
//  ToggleView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct ToggleView: View {
    @StateObject var usersettings = ObserveableReference()

    private var mytext: String?
    private var mybinding: Binding<Bool>

    var body: some View {
        VStack {
            Text(mytext ?? "")
                .foregroundColor(mybinding.wrappedValue ? .green : .gray)
                .toggleStyle(SwitchToggleStyle(tint: .red))
            Toggle(mytext ?? "", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .red))
        }.padding()
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(lineWidth: 2)
                    .foregroundColor(mybinding.wrappedValue ? .green : .gray)
            )
    }

    init(_ text: String, _ binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
    }
}

struct ToggleView2: View {
    @StateObject var usersettings = ObserveableReference()

    private var mytext: String?
    private var mybinding: Binding<Bool>

    var body: some View {
        VStack {
            Text(mytext ?? "")
                .foregroundColor(mybinding.wrappedValue ? .green : .gray)
                .toggleStyle(SwitchToggleStyle(tint: .red))
            Toggle(mytext ?? "", isOn: mybinding)
                .labelsHidden()
                .toggleStyle(CheckmarkToggleStyle())
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 2)
                .foregroundColor(mybinding.wrappedValue ? .green : .gray)
        )
    }

    init(_ text: String, _ binding: Binding<Bool>) {
        mytext = text
        mybinding = binding
    }
}

struct CheckmarkToggleStyle: ToggleStyle {
    typealias ToggleConfiguration = ToggleStyleConfiguration

    func makeBody(configuration: ToggleConfiguration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? .green : .gray)
                .frame(width: 51, height: 31, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3)
                        .overlay(
                            Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .font(Font.title.weight(.black))
                                .frame(width: 8, height: 8, alignment: .center)
                                .foregroundColor(configuration.isOn ? .green : .gray)
                        )
                        .offset(x: configuration.isOn ? 11 : -11, y: 0)
                        .animation(Animation.linear(duration: 0.1))

                ).cornerRadius(20)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

struct PowerToggleStyle: ToggleStyle {
    typealias ToggleConfiguration = ToggleStyleConfiguration

    func makeBody(configuration: ToggleConfiguration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? .green : .gray)
                .frame(width: 51, height: 31, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3)
                        .overlay(
                            GeometryReader { _ in
                                Path { p in
                                    if !configuration.isOn {
                                        p.addRoundedRect(in: CGRect(x: 20, y: 10, width: 10.5, height: 10.5), cornerSize: CGSize(width: 7.5, height: 7.5), style: .circular, transform: .identity)
                                    } else {
                                        p.move(to: CGPoint(x: 51 / 2, y: 10))
                                        p.addLine(to: CGPoint(x: 51 / 2, y: 31 - 10))
                                    }
                                }.stroke(configuration.isOn ? Color.green : Color.gray, lineWidth: 2)
                            }
                        )
                        .offset(x: configuration.isOn ? 11 : -11, y: 0)
                        .animation(Animation.linear(duration: 0.1))

                ).cornerRadius(20)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
