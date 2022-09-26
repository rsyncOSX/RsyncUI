//
//  LocalRemoteInfoView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2022.
//

import SwiftUI

struct LocalRemoteInfoView: View {
    @Binding var dismiss: Bool
    @Binding var data: [String]
    @Binding var selectedconfig: Configuration?


    var body: some View {
        VStack {
            Section(header: header) {
                List(data) { line in
                    Text(line)
                        .modifier(FixedTag(750, .leading))
                }
            }
            
            HStack {
                
                Button("Remote") {
                    let arguments = ArgumentsSynchronize(config: selectedconfig).argumentssynchronize(dryRun: true, forDisplay: false)
                    let task = RsyncAsync(arguments: arguments, config: selectedconfig, processtermination: processtermination)
                    Task {
                        await task.executeProcess()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                
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

extension LocalRemoteInfoView {
    func processtermination(data: [String]?) {
        if self.data.count > 0 {
            for i in 0 ..< (data?.count ?? 0) {
                self.data.append(data?[i] ?? "")
            }
        }
        self.data = data ?? []
    }
}
