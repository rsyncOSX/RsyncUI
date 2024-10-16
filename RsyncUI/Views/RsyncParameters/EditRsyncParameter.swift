//
//  EditRsyncParameter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct EditRsyncParameter: View {
    @State private var selectedparameter = EnumRsyncArguments.select
    var myvalue: Binding<String>
    var mywidth: CGFloat?

    var body: some View {
        HStack {
            dropdownrsyncparameter

            TextField("rsync parameter", text: myvalue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: mywidth)
                .lineLimit(1)
                .onChange(of: selectedparameter) {
                    Task {
                        try await Task.sleep(seconds: 2)
                        let argument = selectedparameter.rawValue
                        let value = parameter(myvalue.wrappedValue)
                        myvalue.wrappedValue = argument + value
                        // selectedparameter = EnumRsyncArguments.select
                    }
                }
        }
    }

    init(_ width: CGFloat, _ value: Binding<String>) {
        mywidth = width
        myvalue = value
    }

    var dropdownrsyncparameter: some View {
        Picker("", selection: $selectedparameter) {
            ForEach(EnumRsyncArguments.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(width: 120)
    }
}

extension EditRsyncParameter {
    func parameter(_ value: String) -> String {
        if value.isEmpty {
            return "="
        } else {
            if let splitparameter = split(value) {
                guard splitparameter.count > 1 else {
                    return "="
                }
                return "=" + splitparameter[1]
            }
        }
        return ""
    }

    // Split an Rsync argument into argument and value
    private func split(_ str: String) -> [String]? {
        let argument: String?
        let value: String?
        // Remove any spaces
        let correctedstring = str.replacingOccurrences(of: " ", with: "")
        let split = correctedstring.components(separatedBy: "=")
        guard split.count > 0 else { return nil }
        argument = String(split[0])
        if split.count > 1 {
            value = String(split[1])
        } else {
            value = argument
        }
        if let argument, let value {
            return [argument, value]
        }
        return nil
    }
    
}

enum EnumRsyncArguments: String, CaseIterable, Identifiable, CustomStringConvertible {
    case backup = "--backup"
    case backupdir = "--backup-dir"
    case excludefrom = "--exclude-from"
    case exclude = "--exclude"
    case includefrom = "--include-from"
    case filesfrom = "--files-from"
    case maxsize = "--max-size"
    case suffix = "--suffix"
    case maxdelete = "--max-delete"
    case include = "--include"
    case filter = "--filter"
    case select

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct ArgumentsRsyncUserSelect {
    // Preselected parameters for storing a backup of deleted or changed files before
    // rsync synchronises the directories
    let backupstrings = ["--backup", "--backup-dir=~/backup", "--backup-dir=../backup"]
}
