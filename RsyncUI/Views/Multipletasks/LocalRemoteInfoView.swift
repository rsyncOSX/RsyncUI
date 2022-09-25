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
            Section(header: header) {
                List(data) { line in
                    Text(line)
                        .modifier(FixedTag(750, .leading))
                }
            }
            
            HStack {
                
                Button("Dismiss") { dismiss = false }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(width: 800, height: 400)
    }
    
    var header: some View {
        Text("Seksjon")
            .modifier(FixedTag(200, .center))
    }
}
