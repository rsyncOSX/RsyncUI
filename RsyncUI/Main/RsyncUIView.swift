//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import OSLog
import SwiftUI

struct RsyncUIView: View {
    @Binding var selectedprofile: String?

    @State private var newversion = CheckfornewversionofRsyncUI()
    @State private var rsyncversion = Rsyncversion()
    @State private var start: Bool = true

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI a GUI for rsync")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    Task {
                        try await Task.sleep(seconds: 1)
                        start = false
                    }

                })
            } else {
                SidebarMainView(rsyncUIdata: rsyncUIdata,
                                selectedprofile: $selectedprofile,
                                errorhandling: errorhandling)
            }

            HStack {
                Spacer()

                if newversion.notifynewversion { notifynewversion }

                Spacer()
            }
            .padding()
        }
        .padding()
        .task {
            ReadUserConfigurationJSON().readuserconfiguration()
            // Get version of rsync
            rsyncversion.getrsyncversion()
            // Check if there is a new version of RsyncUI
            await newversion.getversionsofrsyncui()
        }
    }

    var rsyncUIdata: RsyncUIconfigurations {
        RsyncUIconfigurations(selectedprofile)
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("New version is available")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            Task {
                newversion.dismissnotify()
            }
        })
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

