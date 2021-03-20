//
//  EditRsyncParameters.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import SwiftUI

struct EditRsyncParameter: View {
    @State private var selectedparameter = PredefinedParametersRsync.none
    var myvalue: Binding<String>
    var mytext: String?
    var mywidth: CGFloat?

    var body: some View {
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
        Picker(NSLocalizedString("Parameter", comment: "AddConfigurationsView") + ":",
               selection: $selectedparameter) {
            ForEach(PredefinedParametersRsync.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(width: 200)
    }
}

enum PredefinedParametersRsync: String, CaseIterable, Identifiable, CustomStringConvertible {
    case backupdir
    case excludefrom
    case exclude
    case includefrom
    case filesfrom
    case maxsize
    case suffix
    case maxdelete
    case include
    case filter
    case backup
    case deleteexcluded
    case none

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

/*
 let rsyncArguments: [Argument] = [
     ("user", 1),
     ("delete", 0),
     ("--backup", 0),
     ("--backup-dir", 1),
     ("--exclude-from", 1),
     ("--exclude", 1),
     ("--include-from", 1),
     ("--files-from", 1),
     ("--max-size", 1),
     ("--suffix", 1),
     ("--max-delete", 1),
     ("--delete-excluded", 0),
     ("--include", 1),
     ("--filter", 1),
 */
