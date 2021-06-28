//
//  SelectConfigurationView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 25/02/2021.
//

import SwiftUI

struct SelectConfigurationView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata

    @Binding var selectedconfig: Configuration?
    @Binding var isPresented: Bool
    // only parameters for configlist, noy used
    @State private var selecteduuids = Set<UUID>()
    @State private var inwork: Int = -1
    @State private var searchText: String = ""

    let selectable = false

    var body: some View {
        VStack {
            ConfigurationsList(selectedconfig: $selectedconfig,
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               selectable: selectable)
            Spacer()

            Button("Select") { dismissview() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
    }

    func dismissview() {
        isPresented = false
    }
}
