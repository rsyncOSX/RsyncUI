//
//  OutputView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 12/01/2021.
//

import SwiftUI

struct OutputRsyncView: View {
    // @Binding var config: Configuration?
    @Binding var isPresented: Bool
    @Binding var valueselectedrow: String
    @Binding var numberoffiles: Int
    var output: [String]

    @State private var selection: String?
    @State private var text = ""

    var body: some View {
        VStack {
            Text("Output from rsync")
                .font(.title2)
                .padding()

            List(listitems, id: \.self, selection: $selection.onChange {
                valueselectedrow = selection ?? ""
            }) { line in
                Text(line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            HStack {
                Spacer()

                TextField("Search", text: $text)

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onDisappear {
            text = valueselectedrow
            if (selection ?? "").count > 0 {
                numberoffiles = output.filter { $0.contains(selection ?? "") }.count
            }
        }
        .onAppear(perform: {
            if valueselectedrow.count > 0 {
                numberoffiles = output.filter { $0.contains(valueselectedrow) }.count
            }
            text = valueselectedrow
        })
    }

    var listitems: [String] {
        if text == "" || text == " " {
            numberoffiles = output.count
            return output
        } else {
            numberoffiles = output.filter { $0.contains(text) }.count
            return output.filter { $0.contains(text) }
        }
    }

    func dismissview() {
        isPresented = false
    }
}
