//
//  CompletedView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/05/2024.
//

import SwiftUI

struct CompletedView: View {
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]
    @State var showtext: Bool = true

    var body: some View {
        VStack {
            if showtext {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title)
                        .imageScale(.large)
                    Text("Synchronize data is completed")
                        .font(.title)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onAppear {
                    Task {
                        try await Task.sleep(seconds: 1)
                        showtext = false
                    }
                }
                .onDisappear {
                    executetaskpath.removeAll()
                }
            }
        }
    }
}
