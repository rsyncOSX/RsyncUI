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
        "rsync parameter"
    }
}

extension EditRsyncParameter {
    func parameter() -> String {
        if myvalue.wrappedValue.isEmpty {
            return selectedparameter.rawValue + "="
        } else {
            let splitparameter = split(myvalue.wrappedValue)
            guard splitparameter.count > 1 else {
                return selectedparameter.rawValue + "="
            }
            return selectedparameter.rawValue + "=" + splitparameter[1]
        }
    }

    // Split an Rsync argument into argument and value
    private func split(_ str: String) -> [String] {
        let argument: String?
        let value: String?
        var split = str.components(separatedBy: "=")
        argument = String(split[0])
        if split.count > 1 {
            if split.count > 2 {
                split.remove(at: 0)
                value = split.joined(separator: "=")
            } else {
                value = String(split[1])
            }
        } else {
            value = argument
        }
        return [argument ?? "", value ?? ""]
    }
}
