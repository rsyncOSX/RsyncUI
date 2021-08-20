//
//  ParametersList.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 05/02/2021.
//

import SwiftUI

struct ParametersList: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    var selectedconfig: Configuration?

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(parameters) { param in
                Text(param.parameter ?? "")
            }
        }
        .padding(10)
        .border(Color.gray)
    }

    var parameters: [Parameter] {
        SetRsyncParameters(selectedconfig).getparameters()
    }
}
