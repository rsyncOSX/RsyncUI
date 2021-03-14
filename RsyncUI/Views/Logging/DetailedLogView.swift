//
//  DetailedLogView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 17/01/2021.
//

import SwiftUI

struct DetailedLogView: View {
    @Binding var config: Configuration?
    @Binding var isPresented: Bool
    @Binding var selectedconfig: Configuration?
    @Binding var selectedlog: Log?

    @State private var selecteduuids = Set<UUID>()

    var body: some View {
        VStack {
            LogListView(selectedconfig: $selectedconfig,
                        selectedlog: $selectedlog,
                        selecteduuids: $selecteduuids)

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 600)
    }

    func dismissview() {
        isPresented = false
    }
}
