//
//  LogfileView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 09/02/2021.
//

import Foundation
import SwiftUI

struct LogfileView: View {
    @State private var resetloggfile = false

    var body: some View {
        VStack {
            Section(header: header) {
                List(textfile) { record in
                    Text(record.line)
                        .modifier(FixedTag(750, .leading))
                }
                .onChange(of: resetloggfile, perform: { _ in
                    afterareload()
                })
            }
            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Reset", comment: "Reset button")) { reset() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    var header: some View {
        Text(NSLocalizedString("Logfile", comment: "Logs"))
            .modifier(FixedTag(200, .center))
    }

    var textfile: [Outputrecord] {
        return Logfile().getlogfile()
    }

    func reset() {
        resetloggfile = true
        _ = Logfile(nil, false)
    }

    func afterareload() {
        resetloggfile = false
    }
}
