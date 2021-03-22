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
        /*
         let parameter = Binding<PredefinedParametersRsync>(
             get: { selectedparameter },
             set: { selectedparameter = $0 }
         )
         */
        HStack {
            dropdownrsyncparameter

            TextField(mytext ?? "", text: myvalue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: mywidth)
                .lineLimit(1)
        }
    }

    init(_ width: CGFloat, _ text: String?, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
        mytext = text
    }

    var dropdownrsyncparameter: some View {
        Picker("", selection: $selectedparameter.onChange {
            myvalue.wrappedValue = selectedparameter.rawValue + "="
        }) {
            ForEach(EnumRsyncArguments.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(width: 120)
    }
}
