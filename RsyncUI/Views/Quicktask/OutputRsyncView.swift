//
//  OutputRsyncView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import SwiftUI

struct OutputRsyncView: View {
    @Binding var isPresented: Bool
    @Binding var valueselectedrow: String
    @Binding var numberoffiles: Int

    var output: [String]

    @State private var selection: String?

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

                TextField("Search", text: $valueselectedrow)

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onDisappear {
            if (selection ?? "").count > 0 {
                numberoffiles = output.filter { $0.contains(selection ?? "") }.count
            } else {
                numberoffiles = output.count
                valueselectedrow = ""
            }
        }
        .onAppear(perform: {
            if valueselectedrow.count > 0 {
                numberoffiles = output.filter { $0.contains(valueselectedrow) }.count
            }
        })
    }

    var listitems: [String] {
        if valueselectedrow == "" || valueselectedrow == " " {
            numberoffiles = output.count
            return output
        } else {
            numberoffiles = output.filter { $0.contains(valueselectedrow) }.count
            return output.filter { $0.contains(valueselectedrow) }
        }
    }

    func dismissview() {
        isPresented = false
    }
}
