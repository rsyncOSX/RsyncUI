//
//  LocalRemoteInfoView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2022.
//

import SwiftUI

struct LocalRemoteInfoView: View {
    @Binding var dismiss: Bool
    var data: [String]


    var body: some View {
        VStack {
            Text("Welcome to RsyncUI")
                .font(.title)

            Text("Text")
            
            HStack {
                
                Button("Dismiss") { dismiss = false }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(width: 800, height: 400)
    }
}
