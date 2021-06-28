//
//  LogfileView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 09/02/2021.
//

import Foundation
import SwiftUI

struct LogfileView: View {
    @Binding var viewlogfile: Bool
    @State private var resetloggfile = false

    var body: some View {
        VStack {
            Section(header: header) {
                List(textfile) { line in
                    Text(line)
                        .modifier(FixedTag(750, .leading))
                }
                .onChange(of: resetloggfile, perform: { _ in
                    afterareload()
                })
            }
            Spacer()

            HStack {
                Spacer()

                Button("Reset") { reset() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    var header: some View {
        Text("Logfile")
            .modifier(FixedTag(200, .center))
    }

    var textfile: [String] {
        return Logfile(false).getlogfile()
    }

    func reset() {
        resetloggfile = true
        _ = Logfile(true)
    }

    func afterareload() {
        resetloggfile = false
    }

    func dismiss() {
        viewlogfile = false
    }
}
