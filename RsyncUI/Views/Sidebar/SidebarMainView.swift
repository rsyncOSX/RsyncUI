//
//  SidebarMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import OSLog
import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, snapshots, restore, profiles
    var id: String {
        rawValue
    }
}

/// The sidebar is context sensitive, it is computed everytime a new profile is loaded
struct MenuItem: Identifiable, Hashable {
    var menuitem: Sidebaritems
    let id = UUID()
}

struct SidebarMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // The selectedprofileID is updated by the profile picker
    // The selectedprofileID is monitored by the RsyncUIView and when changed
    // a new profile is loaded
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Bindable var errorhandling: AlertError
    
    @State private var progressdetails = ProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State var selectedview: Sidebaritems = .synchronize
    /// paths used in NavigationStack, there are three parts where
    /// NavigationStack is utilized
    /// Navigation path for executetasks
    @State var executetaskpath: [Tasks] = []
    /// Verify navigation
    /// @State private var verifypath: [Verify] = []
    /// Check if new version
    @State private var newversion = CheckfornewversionofRsyncUI()
    /// URL code
    @State var queryitem: URLQueryItem?
    // Bindings in TaskView triggered when Toolbar Icons, in TaskView, are pressed
    // Toolbar Icons with yellow icons
    @State var urlcommandestimateandsynchronize = false
    @State var urlcommandverify = false
    /// Toggle sidebar
    @State var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    /// .doubleColumn
    /// .detailOnly
    @State var mountingvolumenow: Bool = false
    // Calendar
    @State private var schedules = ObservableSchedules()
    let globaltimer = GlobalTimer.shared
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Only show profile picker if there are other profiles
            // Id default only, do not show profile picker
            
            if rsyncUIdata.validprofiles.isEmpty == false, selectedview != .profiles {
                Picker("", selection: $selectedprofileID) {
                    Text("Default")
                        .tag(nil as ProfilesnamesRecord.ID?)
                    ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                        Text(profile.profilename)
                            .tag(profile.id)
                    }
                }
                .frame(width: 180)
                .padding([.bottom, .top, .trailing], 7)
                .disabled(disablesidebarmeny)
            }
            
            Divider()
            
            
            List(selection: $selectedview) {
                
                // Synchronize
                NavigationLinkWithHover( item: .synchronize, selectedview: $selectedview
                )
                
                // Tasks
                NavigationLinkWithHover(  item: .tasks,selectedview: $selectedview
                )
                
                Divider()
                
                // Snapshots (conditional)
                if rsyncUIdata.oneormoretasksissnapshot {
                    NavigationLinkWithHover( item: .snapshots,  selectedview: $selectedview
                    )
                    Divider()
                }
                
                // Restore (conditional)
                if showRestoreMenu {
                    NavigationLinkWithHover(   item: .restore, selectedview: $selectedview
                    )
                    Divider()
                }
                
                // Profiles
                NavigationLinkWithHover(   item: .profiles, selectedview: $selectedview
                )
            }
            .listStyle(.sidebar)
            .disabled(disablesidebarmeny)
            
            if newversion.notifynewversion {
                MessageView(mytext: "New version available\nsee About RsyncUI", size: .caption2)
                    .padding([.bottom], -30)
            }
            
            if mountingvolumenow {
                MessageView(mytext: "Mounting volume\nplease wait", size: .caption2)
                    .padding([.bottom], -30)
                    .onAppear {
                        Task {
                            try await Task.sleep(seconds: 2)
                            mountingvolumenow = false
                        }
                    }
            }
            
            // Next scheduled action
            if GlobalTimer.shared.timerIsActive() {
                MessageView(mytext: GlobalTimer.shared.nextScheduleDate() ?? "", size: .caption2)
                    .padding([.bottom], -30)
            }
            
            if GlobalTimer.shared.thereisnotexecutedschedulesafterwakeup {
                MessageView(mytext: "Not executed schedules\nafter wakeup", size: .caption2)
                    .padding([.bottom], -30)
                    .onAppear {
                        Task {
                            try await Task.sleep(seconds: 5)
                            GlobalTimer.shared.thereisnotexecutedschedulesafterwakeup = false
                        }
                    }
            }
            
            MessageView(mytext: SharedReference.shared.rsyncversionshort ?? "", size: .caption2)
        } detail: {
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            if let error = errorhandling.activeError {
                Alert(localizedError: error)
            } else {
                Alert(title: Text("No error"))
            }
        })
        .task {
            newversion.notifynewversion = await ActorGetversionofRsyncUI().getversionsofrsyncui()
            SharedReference.shared.newversion = newversion.notifynewversion
            if SharedReference.shared.sidebarishidden {
                columnVisibility = .detailOnly
            }
            // Only addObserver if there are more than the default profile
            if SharedReference.shared.observemountedvolumes,
               rsyncUIdata.validprofiles.isEmpty == false {
                // Observer for mounting volumes
                observerDidMountNotification()
                observerDidUnmountNotification()
            }
            if let scheduledata = await ActorReadSchedule()
                .readjsonfilecalendar(rsyncUIdata.validprofiles.map(\.profilename)) {
                guard scheduledata.count > 0 else { return }
                schedules.appendschdeuldatafromfile(scheduledata)
            }
            
            // Delete any default UserSetttings applied within AddTask
            UserDefaults.standard.removeObject(forKey: "trailingslashoptions")
            UserDefaults.standard.removeObject(forKey: "selectedrsynccommand")
        }
        .onOpenURL { incomingURL in
            // URL code
            // Deep link triggered RsyncUI from outside
            handleURLSidebarMainView(incomingURL, externalURL: true)
        }
        .onChange(of: urlcommandestimateandsynchronize) {
            // URL code
            // Binding to listen for initiating deep link execute estimate and synchronize from
            let valueprofile = rsyncUIdata.profile
            if let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: valueprofile) {
                handleURLSidebarMainView(url, externalURL: false)
            }
        }.onChange(of: selectedprofileID) {
            // Only clean selecteuuids, new profile is loaded
            // in RsyncUIView
            selecteduuids.removeAll()
        }
        .onChange(of: globaltimer.firstscheduledate) {
            if globaltimer.allSchedules.isEmpty {
                globaltimer.invalidateAllSchedulesAndTimer()
            }
        }
        .onChange(of: globaltimer.scheduledprofile) {
            queryitem = nil
            if selectedview != .synchronize {
                selectedview = .synchronize
            }
            // Trigger as external URL, makes it load profile before execute
            if let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: globaltimer.scheduledprofile) {
                handleURLSidebarMainView(url, externalURL: true)
            }
        }
    }
    
    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            NavigationStack {
                EditTabView(rsyncUIdata: rsyncUIdata)
            }
        case .restore:
            NavigationStack {
                RestoreTableView(profile: $rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
            }
        case .snapshots:
            SnapshotsView(rsyncUIdata: rsyncUIdata)
        case .synchronize:
            SidebarTasksView(rsyncUIdata: rsyncUIdata,
                             progressdetails: progressdetails,
                             schedules: schedules,
                             selecteduuids: $selecteduuids,
                             executetaskpath: $executetaskpath,
                             queryitem: $queryitem,
                             urlcommandestimateandsynchronize: $urlcommandestimateandsynchronize,
                             columnVisibility: $columnVisibility,
                             selectedprofileID: $selectedprofileID)
        case .profiles:
            ProfileView(rsyncUIdata: rsyncUIdata, selectedprofileID: $selectedprofileID)
        }
    }
    
    var disablesidebarmeny: Bool {
        executetaskpath.isEmpty == false ||
        SharedReference.shared.process != nil
    }
    
    var showRestoreMenu: Bool {
        if SharedReference.shared.rsyncversion3 {
            return rsyncUIdata.oneormoresynchronizetasksisremoteVer3x ||
            rsyncUIdata.oneormoresnapshottasksisremote
        } else {
            return rsyncUIdata.oneormoresynchronizetasksisremoteOrsync
        }
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems
    
    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemImage(sidebaritem))
    }
    
    func systemImage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            "text.badge.plus"
        case .restore:
            "arrowshape.turn.up.forward"
        case .snapshots:
            "text.badge.plus"
        case .synchronize:
            "arrowshape.turn.up.backward"
        case .profiles:
            "arrow.left.arrow.right.circle.fill"
        }
    }
}

struct NavigationLinkWithHover: View {
    let item: Sidebaritems
    @Binding var selectedview: Sidebaritems
    @State private var isHovered = false
    
    var body: some View {
        NavigationLink(value: item) {
            SidebarRow(sidebaritem: item)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.blue.opacity(0.2) : Color.clear)
                .padding(.horizontal, 10)
        )
        .listRowInsets(EdgeInsets())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
