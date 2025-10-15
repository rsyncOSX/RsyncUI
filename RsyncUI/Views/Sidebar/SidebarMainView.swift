//
//  SidebarMainView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/12/2023.
//

import OSLog
import SwiftUI

enum Sidebaritems: String, Identifiable, CaseIterable {
    case synchronize, tasks, rsync_parameters, verify_tasks, snapshots, log_listings, restore, profiles, verify_remote, schedule
    var id: String { rawValue }
}

// The sidebar is context sensitive, it is computed everytime a new profile is loaded
struct MenuItem: Identifiable, Hashable {
    var menuitem: Sidebaritems
    let id = UUID()
}

struct SidebarMainView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var scheduledata: ObservableScheduleData
    // The selectedprofileID is updated by the profile picker
    // The selectedprofileID is monitored by the RsyncUIView and when changed
    // a new profile is loaded
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Bindable var errorhandling: AlertError

    @State private var progressdetails = ProgressDetails()
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var selectedview: Sidebaritems = .synchronize
    // paths used in NavigationStack, there are three parts where
    // NavigationStack is utilized
    // Navigation path for executetasks
    @State var executetaskpath: [Tasks] = []
    // Navigation addtasks and verify
    // Needed here because if not empty sidebar is disabled
    @State private var addtaskpath: [AddTasks] = []
    // Verify navigation
    @State private var verifypath: [Verify] = []
    // Check if new version
    @State private var newversion = CheckfornewversionofRsyncUI()
    // URL code
    @State var queryitem: URLQueryItem?
    // Bindings in TaskView triggered when Toolbar Icons, in TaskView, are pressed
    // Toolbar Icons with yellow icons
    @State var urlcommandestimateandsynchronize = false
    @State var urlcommandverify = false
    // Toggle sidebar
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    // .doubleColumn
    // .detailOnly
    @State private var mountingvolumenow: Bool = false
    // Calendar
    @State private var futuredates = ObservableFutureSchedules()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Only show profile picker if there are other profiles
            // Id default only, do not show profile picker

            if rsyncUIdata.validprofiles.isEmpty == false {
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

            List(menuitems, selection: $selectedview) { item in
                NavigationLinkWithHover(item: item, selectedview: $selectedview)

                if item.menuitem == .tasks ||
                    item.menuitem == .verify_tasks ||
                    item.menuitem == .snapshots ||
                    item.menuitem == .log_listings ||
                    item.menuitem == .restore ||
                    item.menuitem == .verify_remote

                { Divider() }
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

            MessageView(mytext: SharedReference.shared.rsyncversionshort ?? "", size: .caption2)

        } detail: {
            selectView(selectedview)
        }
        .alert(isPresented: errorhandling.presentalert, content: {
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
               rsyncUIdata.validprofiles.isEmpty == false
            {
                // Observer for mounting volumes
                observerdidMountNotification()
                observerdiddidUnmountNotification()
            }
            // Compute schedules
            futuredates.scheduledata = scheduledata.scheduledata
            futuredates.recomputeschedules()
            // Set first schedule to execute
            futuredates.setfirsscheduledate()
            Logger.process.info("SidebarMainView: ONAPPEAR completed")

            // Delete any default UserSetttings applied within AddTask
            UserDefaults.standard.removeObject(forKey: "trailingslashoptions")
            UserDefaults.standard.removeObject(forKey: "selectedrsynccommand")
        }
        .onOpenURL { incomingURL in
            // URL code
            // Deep link triggered RsyncUI from outside
            handleURLsidebarmainView(incomingURL, externalurl: true)
        }
        .onChange(of: urlcommandestimateandsynchronize) {
            // URL code
            // Binding to listen for initiating deep link execute estimate and synchronize from
            // toolbar in TasksView
            let valueprofile = rsyncUIdata.profile
            if let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: valueprofile) {
                handleURLsidebarmainView(url, externalurl: false)
            }
        }
        .onChange(of: urlcommandverify) {
            // URL code
            // Binding to listen for initiating deep link execute estimate and synchronize from
            // toolbar in Verify View
            guard urlcommandverify == true else { return }
            let valueprofile = rsyncUIdata.profile
            var valueid = ""
            if let configurations = rsyncUIdata.configurations {
                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                    valueid = configurations[index].backupID
                    if let url = DeeplinkURL().createURLloadandverify(valueprofile: valueprofile,
                                                                      valueid: valueid)
                    {
                        handleURLsidebarmainView(url, externalurl: false)
                    }
                }
            }
        }.onChange(of: selectedprofileID) {
            // Only clean selecteuuids, new profile is loaded
            // in RsyncUIView
            selecteduuids.removeAll()
        }
        .onChange(of: futuredates.firstscheduledate) {
            if futuredates.firstscheduledate == nil {
                scheduledata.scheduledata.removeAll()
            } else {
                scheduledata.removeexecutedonce()
            }
            if scheduledata.scheduledata.isEmpty {
                let globalTimer = GlobalTimer.shared
                globalTimer.clearSchedules()
            }
        }
        .onChange(of: futuredates.scheduledprofile) {
            Logger.process.info("SidebarMainView: got TRIGGER from Timer")

            queryitem = nil
            if selectedview != .synchronize {
                selectedview = .synchronize
            }
            // Trigger as external URL, makes it load profile before execute
            if let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: futuredates.scheduledprofile) {
                handleURLsidebarmainView(url, externalurl: true)
            }
        }
    }

    @MainActor @ViewBuilder
    func selectView(_ view: Sidebaritems) -> some View {
        switch view {
        case .tasks:
            AddTaskView(rsyncUIdata: rsyncUIdata,
                        selecteduuids: $selecteduuids,
                        addtaskpath: $addtaskpath)
        case .log_listings:
            LogsbyConfigurationView(rsyncUIdata: rsyncUIdata)
        case .rsync_parameters:
            NavigationStack {
                RsyncParametersView(rsyncUIdata: rsyncUIdata, selecteduuids: $selecteduuids)
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
                             selecteduuids: $selecteduuids,
                             executetaskpath: $executetaskpath,
                             queryitem: $queryitem,
                             urlcommandestimateandsynchronize: $urlcommandestimateandsynchronize,
                             columnVisibility: $columnVisibility,
                             selectedprofileID: $selectedprofileID)
        case .profiles:
            ProfileView(rsyncUIdata: rsyncUIdata, selectedprofileID: $selectedprofileID)
        case .verify_remote:
            VerifyRemoteView(rsyncUIdata: rsyncUIdata,
                             verifypath: $verifypath,
                             urlcommandverify: $urlcommandverify,
                             queryitem: $queryitem)
        case .schedule:
            NavigationStack {
                CalendarMonthView(rsyncUIdata: rsyncUIdata,
                                  scheduledata: scheduledata,
                                  futuredates: futuredates,
                                  selectedprofileID: $selectedprofileID)
            }
        case .verify_tasks:
            NavigationStack {
                VerifyTasks(rsyncUIdata: rsyncUIdata)
            }
        }
    }

    var disablesidebarmeny: Bool {
        executetaskpath.isEmpty == false ||
            addtaskpath.isEmpty == false ||
            verifypath.isEmpty == false ||
            SharedReference.shared.process != nil
    }

    // The Sidebar meny is context sensitive. There are three Sidebar meny options
    // which are context sensitive:
    // - Snapshots
    // - Verify remote
    // - Restore
    var menuitems: [MenuItem] {
        Sidebaritems.allCases.compactMap { item in
            // Return nil if there is one or more snapshot tasks
            // Do not show the Snapshot sidebar meny
            if rsyncUIdata.oneormoretasksissnapshot == false,
               item == .snapshots { return nil }

            if SharedReference.shared.hideverifyremotefunction == true,
               item == .verify_remote { return nil }

            if SharedReference.shared.hideschedule == true,
               item == .schedule { return nil }

            // Return nil if there is one or more remote tasks
            // and only remote task is snapshot
            // Do not show the Verify remote sidebar meny
            if rsyncUIdata.oneormoretasksissnapshot == true,
               SharedReference.shared.hideverifyremotefunction == false,
               item == .verify_remote { return nil }

            // Return nil if there is no remote tasks, only local attached discs
            // Do not show the Verify remote sidebar meny
            if rsyncUIdata.oneormoresynchronizetasksisremoteVer3x == false,
               item == .verify_remote { return nil }

            // Return nil if there is no remote tasks, only local attached discs
            // Do not show the Restore remote sidebar meny

            if SharedReference.shared.rsyncversion3 {
                if rsyncUIdata.oneormoresynchronizetasksisremoteVer3x == false,
                   rsyncUIdata.oneormoresnapshottasksisremote == false,
                   item == .restore { return nil }
            } else {
                if rsyncUIdata.oneormoresynchronizetasksisremoteOpenrsync == false,
                   item == .restore { return nil }
            }

            return MenuItem(menuitem: item)
        }
    }
}

extension SidebarMainView {
    // URL code
    private func handleURLsidebarmainView(_ url: URL, externalurl: Bool) {
        let deeplinkurl = DeeplinkURL()
        // Verify URL action is valid
        guard deeplinkurl.validatenoaction(queryitem) else { return }
        // Verify no other process is running
        guard SharedReference.shared.process == nil else { return }
        // Also veriy that no other query item is processed
        guard queryitem == nil else { return }
        // And no xecution is in progress
        guard rsyncUIdata.executetasksinprogress == false else { return }

        switch deeplinkurl.handleURL(url)?.host {
        case .quicktask:
            Logger.process.info("handleURLsidebarmainView: URL Quicktask - \(url)")

            selectedview = .synchronize
            executetaskpath.append(Tasks(task: .quick_synchronize))
        case .loadprofile:
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile - \(url)")

            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                let profile = queryitems[0].value
                if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                    if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == profile }) {
                        // Set the profile picker and let the picker do the job
                        selectedprofileID = rsyncUIdata.validprofiles[index].id
                    }
                }
            } else {
                return
            }
        case .loadprofileandestimate:
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile and Estimate - \(url)")

            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 {
                let profile = queryitems[0].value

                selectedview = .synchronize

                if profile == "Default" || profile == "default" {
                    Task {
                        if externalurl {
                            // Load profile for external URL, this make the call structured concurrency
                            async let loadprofile = loadprofileforexternalurllink(nil)
                            guard await loadprofile else { return }
                        }
                        guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                            selectedview = .synchronize
                            return
                        }
                        // Observe queryitem
                        queryitem = queryitems[0]
                    }
                } else {
                    if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                        Task {
                            if externalurl {
                                // Load profile for external URL
                                async let loadprofile = loadprofileforexternalurllink(profile)
                                guard await loadprofile else { return }
                            }
                            guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                                selectedview = .synchronize
                                return
                            }
                            // Observe queryitem
                            queryitem = queryitems[0]
                        }
                    }
                }

            } else {
                return
            }
        case .loadprofileandverify:
            // Only by external URL load and verify
            Logger.process.info("handleURLsidebarmainView: URL Loadprofile and Verify - \(url)")

            guard SharedReference.shared.hideverifyremotefunction == false else {
                Logger.process.warning("handleURLsidebarmainView: URL Loadprofile and Verify - \(url) not enabled")
                return
            }
            if let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 2 {
                let profile = queryitems[0].value ?? ""

                // Internal verify remote is triggered from within the verify_remote view
                // and external == false, the view itself handles push and pull dryrun
                if selectedview != .verify_remote {
                    selectedview = .verify_remote
                }

                if profile == "Default" || profile == "default" {
                    Task {
                        if externalurl {
                            // Load profile for external URL
                            async let loadprofile = loadprofileforexternalurllink(profile)
                            guard await loadprofile else { return }

                            guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                                selectedview = .synchronize
                                return
                            }
                            // Observe queryitem
                            queryitem = queryitems[1]
                        }
                    }
                } else {
                    if deeplinkurl.validateprofile(profile, rsyncUIdata.validprofiles) {
                        Task {
                            if externalurl {
                                // Load profile for external URL
                                async let loadprofile = loadprofileforexternalurllink(profile)
                                guard await loadprofile else { return }

                                guard rsyncUIdata.configurations?.count ?? 0 > 0 else {
                                    selectedview = .synchronize
                                    return
                                }
                                // Observe queryitem
                                queryitem = queryitems[1]
                            }
                        }
                    }
                }
            } else {
                return
            }
        default:
            return
        }
    }

    func observerdidMountNotification() {
        Logger.process.info("SidebarMainView: observerdidMountNotification added")

        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didMountNotification,
                                       object: nil, queue: .main)
        { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                Logger.process.info("SidebarMainView: observerdidMountNotification \(volumeURL)")
                Task {
                    guard await tasksareinprogress() == false else { return }
                    await verifyandloadprofilemountedvolume(volumeURL)
                }
            }
        }
    }

    func observerdiddidUnmountNotification() {
        Logger.process.info("SidebarMainView: observerdidUnmountNotification added")

        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification,
                                       object: nil, queue: .main)
        { _ in
            Logger.process.info("SidebarMainView: observerdidUnmountNotification")
            Task {
                guard await tasksareinprogress() == false else { return }
                await verifyandloadprofilemountedvolume(nil)
            }
        }
    }

    private func verifyandloadprofilemountedvolume(_ mountedvolume: URL?) async {
        if let mountedvolume {
            mountingvolumenow = true

            let allconfigurations = await ReadAllTasks().readalltasks(rsyncUIdata.validprofiles)

            let volume = mountedvolume.lastPathComponent
            let mappedallconfigurations = allconfigurations.compactMap { configuration in
                (configuration.offsiteServer.isEmpty == true &&
                    configuration.offsiteCatalog.contains(volume) == true &&
                    configuration.task != SharedReference.shared.halted) ? configuration : nil
            }
            let profiles = mappedallconfigurations.compactMap(\.backupID)
            guard profiles.count > 0 else {
                mountingvolumenow = false
                return
            }
            let uniqprofiles = Set(profiles)
            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == uniqprofiles.first }) {
                // Set the profile picker and let the picker do the job
                selectedprofileID = rsyncUIdata.validprofiles[index].id
            }
        } else {
            // Load default profile
            selectedprofileID = nil
        }
    }

    // Must check that no tasks are running
    private func tasksareinprogress() async -> Bool {
        guard SharedReference.shared.process == nil else { return true }
        // And no execution is in progress
        guard rsyncUIdata.executetasksinprogress == false else { return true }
        guard executetaskpath.isEmpty == true else {
            return true
        }
        return false
    }

    // Must load profile for URL-link async to make sure profile is
    // loaded ahead of start requested action. Only for external URL requests
    func loadprofileforexternalurllink(_ profile: String?) async -> Bool {
        Logger.process.info("SidebarMainView: loadprofileforexternalurllink executed")
        rsyncUIdata.externalurlrequestinprogress = true
        if profile == nil {
            rsyncUIdata.profile = nil
            selectedprofileID = nil
        } else {
            rsyncUIdata.profile = profile
            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == profile }) {
                // Set the profile picker and let the picker do the job
                selectedprofileID = rsyncUIdata.validprofiles[index].id
            }
        }

        rsyncUIdata.configurations = await ActorReadSynchronizeConfigurationJSON()
            .readjsonfilesynchronizeconfigurations(profile,
                                                   SharedReference.shared.rsyncversion3,
                                                   SharedReference.shared.monitornetworkconnection,
                                                   SharedReference.shared.sshport)

        if rsyncUIdata.configurations == nil {
            return false
        } else {
            return true
        }
    }
}

struct SidebarRow: View {
    var sidebaritem: Sidebaritems

    var body: some View {
        Label(sidebaritem.rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " "),
              systemImage: systemimage(sidebaritem))
    }

    func systemimage(_ view: Sidebaritems) -> String {
        switch view {
        case .tasks:
            "text.badge.plus"
        case .log_listings:
            "text.alignleft"
        case .rsync_parameters:
            "command.circle.fill"
        case .restore:
            "arrowshape.turn.up.forward"
        case .snapshots:
            "text.badge.plus"
        case .synchronize:
            "arrowshape.turn.up.backward"
        case .profiles:
            "arrow.triangle.branch"
        case .verify_remote:
            "arrow.left.arrow.right.circle.fill"
        case .schedule:
            "calendar.circle.fill"
        case .verify_tasks:
            "hand.thumbsup.fill"
        }
    }
}

struct NavigationLinkWithHover: View {
    let item: MenuItem // Replace with your actual item type
    @Binding var selectedview: Sidebaritems // Replace with your selection type
    @State private var isHovered = false

    var body: some View {
        NavigationLink(value: item.menuitem) {
            SidebarRow(sidebaritem: item.menuitem)
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
