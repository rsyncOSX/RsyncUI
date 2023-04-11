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
    @StateObject private var logfileview = Logfileview()

    var body: some View {
        VStack {
            Section(header: header) {
                List(logfileview.output) { output in
                    Text(output.line)
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
        .onAppear {
            logfileview.generatedata()
        }
    }

    var header: some View {
        Text("Logfile")
            .modifier(FixedTag(200, .center))
    }

    func reset() {
        resetloggfile = true
        _ = Logfile(true)
        logfileview.generatedata()
    }

    func afterareload() {
        resetloggfile = false
    }

    func dismiss() {
        viewlogfile = false
    }
}

final class Logfileview: ObservableObject {
    @Published var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func generatedata() {
        output = [Data]()
        let data = Logfile(false).getlogfile()
        for i in 0 ..< data.count {
            output.append(Data(line: data[i]))
        }
    }
}
