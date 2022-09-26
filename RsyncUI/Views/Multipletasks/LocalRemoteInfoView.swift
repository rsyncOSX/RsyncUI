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
    
    @State private var remotedata: [String] = []

    var body: some View {
        VStack {
            HStack {
                local
                
                remote
            }
                
            Button("Remote") {
                let arguments = ArgumentsSynchronize(config: selectedconfig).argumentssynchronize(dryRun: true, forDisplay: false)
                let task = RsyncAsync(arguments: arguments, config: selectedconfig, processtermination: processtermination)
                Task {
                    await task.executeProcess()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
            
            HStack {
                
            Spacer()
                
                
                
                Button("Dismiss") { dismiss = false }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(width: 800, height: 400)
    }
    
    var local: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Last run" + ": ")
                Text(selectedconfig?.dateRun ?? "")
            }
            HStack {
                Text("Number of files" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumber ?? "")
            }
            HStack {
                Text("Number of catalogs" + ": ")
                Text(remoteinfonumberslocalcatalog.totalDirs ?? "")
            }
            
            HStack {
                Text("Total size (kB)" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumberSizebytes ?? "")
            }
        }
    }
    
    var remote: some View {
        VStack (alignment: .leading) {
          HStack {
              Text("Number of files" + ": ")
              Text(remoteinfonumbersremotecatalog.transferredNumber ?? "")
          }
          HStack {
              Text("KB to be transferred" + ": ")
              Text(remoteinfonumbersremotecatalog.transferredNumberSizebytes ?? "")
          }
          HStack {
              Text("Number of catalogs" + ": ")
              Text(remoteinfonumbersremotecatalog.totalNumber ?? "")
          }
          HStack {
              Text("Total size (kB)" + ": ")
              Text(remoteinfonumbersremotecatalog.totalNumberSizebytes ?? "")
          }
          HStack {
              Text("New files" + ": ")
              Text(remoteinfonumbersremotecatalog.newfiles ?? "")
          }
          HStack {
              Text("Delete files" + ": ")
              Text(remoteinfonumbersremotecatalog.deletefiles ?? "")
          }
                
        }
    }
    
    var remoteinfonumberslocalcatalog: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: localdata)
    }
    
    var remoteinfonumbersremotecatalog: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: remotedata)
    }
}

extension LocalRemoteInfoView {
    func processtermination(data: [String]?) {
        remotedata = data ?? []
    }
}
