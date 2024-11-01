//
//  CompletedView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/05/2024.
//

import SwiftUI

struct CompletedView: View {
    @Binding var path: [Tasks]
    @State var showtext: Bool = true

    var body: some View {
        VStack {
            if showtext {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title)
                        .imageScale(.large)
                        .foregroundColor(.yellow)
                    Text("Synchronize data is completed")
                        .foregroundColor(.yellow)
                        .font(.title)
                }
                .onAppear(perform: {
                    Task {
                        try await Task.sleep(seconds: 2)
                        showtext = false
                    }
                })
                .onDisappear {
                    path.removeAll()
                }
            }
        }
    }
}
