//
//  LocalRemoteInfoView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2022.
//

import SwiftUI

struct LocalRemoteInfoView: View {
    @Binding var dismiss: Bool
    @Binding var localdata: [String]
    @Binding var selectedconfig: Configuration?

    var body: some View {
        VStack {
            Section(header: header) {
                local
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
    
    var local: some View {
        VStack {
            Text(selectedconfig?.dateRun ?? "")
            Text(remoteinfonumbers.totalDirs ?? "")
        }
    }
    
    var remoteinfonumbers: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: localdata)
    }
}

extension LocalRemoteInfoView {
    func processtermination(data: [String]?) {
    }
}
