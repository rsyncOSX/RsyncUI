//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/11/2023.
//

import OSLog
import RsyncProcessStreaming
import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote
    case notSelected

    var id: String {
        rawValue
    }

    var description: String {
        rawValue.localizedLowercase.replacingOccurrences(of: "_", with: " ")
    }
}

enum ValidateInputQuicktask: LocalizedError {
    case localcatalog
    case remotecatalog
    case offsiteusername
    case offsiteserver

    var errorDescription: String? {
        switch self {
        case .localcatalog:
            "Source folder cannot be empty"
        case .offsiteusername:
            "Username cannot be empty"
        case .remotecatalog:
            "Destination folder cannot be empty"
        case .offsiteserver:
            "Servername cannot be empty"
        }
    }
}

struct QuicktaskView: View {
    @State var localcatalog: String = ""
    @State var remotecatalog: String = ""
    @State var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State var remoteuser: String = ""
    @State var remoteserver: String = ""
    @State var trailingslashoptions: TrailingSlash = .add
    @State var dryrun: Bool = true
    @State var catalogorfile: Bool = true
    @State var focusaborttask: Bool = false

    @AppStorage("quicklocalcatalog") var quicklocalcatalog: String = ""
    @AppStorage("quickremotecatalog") var quickremotecatalog: String = ""
    @AppStorage("quickselectedrsynccommand") var quickselectedrsynccommand: String = ""

    @AppStorage("quickremoteuser") var quickremoteuser: String = ""
    @AppStorage("quickremoteserver") var quickremoteserver: String = ""

    @AppStorage("quicktrailingslashoptions") var quicktrailingslashoptions: String = ""
    @AppStorage("quickcatalogorfile") var quickcatalogorfile: Bool = true

    // Executed labels
    @State var showprogressview = false
    @State var rsyncoutput = ObservableRsyncOutput()
    /// Focus buttons from the menu
    @State var focusstartexecution: Bool = false
    /// Completed task
    @State var completed: Bool = false
    // Progress and max if estimate first
    @State var progress: Double = 0
    @State var max: Double = 0

    // Streaming variants
    @State var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    @State var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState var focusField: QuicktaskField?

    @State var selectedhomecatalog: Catalog.ID?
    @State var selectedAttachedVolumeCatalogs: String?

    let homecatalogs: [Catalog]

    var body: some View {
        ZStack {
            QuicktaskFormView(localcatalog: $localcatalog,
                              remotecatalog: $remotecatalog,
                              selectedrsynccommand: $selectedrsynccommand,
                              remoteuser: $remoteuser,
                              remoteserver: $remoteserver,
                              trailingslashoptions: $trailingslashoptions,
                              dryrun: $dryrun,
                              catalogorfile: $catalogorfile,
                              selectedhomecatalog: $selectedhomecatalog,
                              homecatalogs: homecatalogs,
                              localhome: localhome,
                              focusField: _focusField)

            if showprogressview { SynchronizeProgressView(max: max, progress: progress, statusText: "Synchronizing...") }
            if focusaborttask { labelaborttask }
            if focusstartexecution { labelstartexecution }
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                focusField = nil
                dryrun = true
            default:
                return
            }
        }
        .onAppear {
            focusField = .localcatalogField
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .toolbar { toolbarContent }
        .padding()
        .navigationTitle("Quicktask - only for remote server")
        .navigationDestination(isPresented: $completed) {
            OutputRsyncView(output: rsyncoutput.output ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundStyle(.black)
            .onAppear {
                getConfigAndExecute()
            }
    }

    var localhome: String {
        URL.userHomeDirectoryURLPath?.path() ?? ""
    }
}
