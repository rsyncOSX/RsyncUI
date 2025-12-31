//
//  EditValueErrorScheme.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/07/2025.
//

import SwiftUI

struct EditValueErrorScheme<T: LosslessStringConvertible>: View {
    @Environment(\.colorScheme) var colorScheme

    var myvalue: Binding<T>
    var mywidth: CGFloat?
    var myprompt: Text?
    var myerror: Bool

    var body: some View {
        TextField("", text: Binding(
            get: { String(myvalue.wrappedValue) },
            set: { newValue in
                if let converted = T(newValue) {
                    myvalue.wrappedValue = converted
                }
            }
        ), prompt: myprompt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: mywidth, alignment: .trailing)
            .lineLimit(1)
            .foregroundColor(color(error: myerror))
    }

    init(_ width: CGFloat, _ str: String?, _ value: Binding<T>, _ error: Bool) {
        mywidth = width
        myvalue = value
        if let str {
            myprompt = Text(str)
        } else {
            myprompt = nil
        }
        myerror = error
    }

    func color(error: Bool) -> Color {
        error == false ? .red : (colorScheme == .dark ? .white : .black)
    }
}
