//
//  EditRsyncParameters.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct EditRsyncParameter: View {
    @State private var selectedparameter = EnumRsyncArguments.select
    var myvalue: Binding<String>
    var mytext: String?
    var mywidth: CGFloat?

    var body: some View {
        HStack {
            dropdownrsyncparameter

            TextField(text, text: myvalue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: mywidth)
                .lineLimit(1)
        }
    }

    init(_ width: CGFloat, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
    }

    var dropdownrsyncparameter: some View {
        Picker("", selection: $selectedparameter.onChange {
            myvalue.wrappedValue = parameter()
        }) {
            ForEach(EnumRsyncArguments.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(width: 120)
    }

    var text: String {
        NSLocalizedString("rsync parameter", comment: "EditRsyncParameter")
    }
}

extension EditRsyncParameter {
    func parameter() -> String {
        return selectedparameter.rawValue + "="
    }
}
