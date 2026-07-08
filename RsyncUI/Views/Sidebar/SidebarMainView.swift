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
    @State private var globaltimer = GlobalTimer.shared

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROFILE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                Picker("", selection: $selectedprofileID) {
                    Text("Default")
                        .tag(nil as ProfilesnamesRecord.ID?)
                    ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                        Text(profile.profilename)
                            .tag(profile.id)
                    }
                }
                .frame(width: 180)
                .disabled(disablesidebarmeny)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(selection: $selectedview) {
                Section("Actions") {
                    ForEach(actionItems) { item in
                        NavigationLinkWithHover(item: item,
                                                selectedview: $selectedview,
                                                badgeCount: badgeCount(for: item.menuitem))
                    }
                }

                if toolItems.isEmpty == false {
                    Section("Tools") {
                        ForEach(toolItems) { item in
                            NavigationLinkWithHover(item: item,
                                                    selectedview: $selectedview,
                                                    badgeCount: badgeCount(for: item.menuitem))
                        }
                    }
                }

                Section("Management") {
                    ForEach(managementItems) { item in
                        NavigationLinkWithHover(item: item,
                                                selectedview: $selectedview,
                                                badgeCount: badgeCount(for: item.menuitem))
                    }
                }
            }
            .listStyle(.sidebar)
            .disabled(disablesidebarmeny)

            SidebarStatusMessagesView(newVersionAvailable: newversion.notifynewversion,
                                      mountingVolumeNow: $mountingvolumenow,
                                      timerIsActive: GlobalTimer.shared.timerIsActive(),
                                      nextScheduleText: GlobalTimer.shared.nextScheduleDate() ?? "",
                                      showNotExecutedAfterWake: GlobalTimer.shared.thereisnotexecutedschedulesafterwakeup,
                                      rsyncVersionShort: SharedReference.shared.rsyncversionshort ?? "",
                                      clearNotExecutedAfterWake: {
                                          GlobalTimer.shared.thereisnotexecutedschedulesafterwakeup = false
                                      })
        } detail: {
            selectView(selectedview)
        }
        .alert(errorhandling.activeError?.localizedDescription ?? "No error", isPresented: errorhandling.isPresentingAlert) {
            Button("OK", role: .cancel) {}
        }
        .task {
            let result = await loadData()

            newversion.notifynewversion = result.version
            SharedReference.shared.newversion = result.version

            if result.scheduledata.count > 0 {
                schedules.appendschdeuldatafromfile(result.scheduledata)
            }

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

    func loadData() async -> (version: Bool, scheduledata: [SchedulesConfigurations]) {
        async let version = GetversionofRsyncUI.shared.getversionsofrsyncui()
        async let scheduledata = ReadSchedule()
            .readjsonfilecalendar(rsyncUIdata.validprofiles.map(\.profilename)) ?? []

        return await (version, scheduledata)
    }

    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            NavigationStack {
                TasksView(rsyncUIdata: rsyncUIdata)
            }
        case .restore:
            NavigationStack {
                RestoreTableView(profile: $rsyncUIdata.profile,
                                 configurations: rsyncUIdata.configurations ?? [])
            }
        case .snapshots:
            SnapshotsView(rsyncUIdata: rsyncUIdata)
        case .synchronize:
            SynchronizeView(rsyncUIdata: rsyncUIdata,
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

    var actionItems: [MenuItem] {
        menuitems.filter { $0.menuitem == .synchronize || $0.menuitem == .tasks }
    }

    var toolItems: [MenuItem] {
        menuitems.filter { $0.menuitem == .snapshots || $0.menuitem == .restore }
    }

    var managementItems: [MenuItem] {
        menuitems.filter { $0.menuitem == .profiles }
    }

    /// The Sidebar meny is context sensitive. There are three Sidebar meny options
    /// which are context sensitive:
    /// - Snapshots
    /// - Verify remote
    /// - Restore
    var menuitems: [MenuItem] {
        Sidebaritems.allCases.compactMap { item in
            // Return nil if there is one or more snapshot tasks
            // Do not show the Snapshot sidebar meny
            if rsyncUIdata.oneormoretasksissnapshot == false,
               item == .snapshots { return nil }
            // Return nil if there is no remote tasks, only local attached discs
            // Do not show the Restore remote sidebar meny

            if SharedReference.shared.rsyncversion3 {
                if rsyncUIdata.oneormoresynchronizetasksisremoteVer3x == false,
                   rsyncUIdata.oneormoresnapshottasksisremote == false,
                   item == .restore { return nil }
            } else {
                if rsyncUIdata.oneormoresynchronizetasksisremoteOrsync == false,
                   item == .restore { return nil }
            }

            return MenuItem(menuitem: item)
        }
    }

    private func badgeCount(for item: Sidebaritems) -> Int {
        guard item == .synchronize else { return 0 }
        return configurationsNeedingSyncCount
    }

    private var configurationsNeedingSyncCount: Int {
        (rsyncUIdata.configurations ?? []).filter { config in
            guard config.task != SharedReference.shared.halted else { return false }
            guard let dateRun = config.dateRun else { return true }
            let lastRun = dateRun.en_date_from_string()
            let daysSince = lastRun.timeIntervalSinceNow * -1 / (60 * 60 * 24)
            return daysSince > Double(SharedReference.shared.marknumberofdayssince)
        }.count
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems
    var badgeCount: Int = 0

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemImage(sidebaritem))
            .badge(badgeCount > 0 ? badgeCount : 0)
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
    let item: MenuItem // Replace with your actual item type
    @Binding var selectedview: Sidebaritems // Replace with your selection type
    var badgeCount: Int = 0
    @State private var isHovered = false

    var body: some View {
        NavigationLink(value: item.menuitem) {
            SidebarRow(sidebaritem: item.menuitem, badgeCount: badgeCount)
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
