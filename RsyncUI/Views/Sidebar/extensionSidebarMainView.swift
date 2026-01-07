//
//  SidebarRowView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//
import OSLog
import SwiftUI

extension SidebarMainView {
    // URL code
    func handleURLSidebarMainView(_ url: URL, externalURL: Bool) {
        let deeplinkurl = DeeplinkURL()
        // Verify URL action is valid
        guard deeplinkurl.validateNoAction(queryitem) else { return }
        // Verify no other process is running
        guard SharedReference.shared.process == nil else { return }
        // Also veriy that no other query item is processed
        guard queryitem == nil else { return }
        // And no xecution is in progress
        guard rsyncUIdata.executetasksinprogress == false else { return }

        switch deeplinkurl.handleURL(url)?.host {
        case .quicktask:
            handleQuickTask()
        case .loadprofile:
            handleLoadProfile(url, deeplinkurl)
        case .loadprofileandestimate:
            handleLoadProfileAndEstimate(url, deeplinkurl, externalURL)
        default:
            return
        }
    }

    private func handleQuickTask() {
        selectedview = .synchronize
        executetaskpath.append(Tasks(task: .quick_synchronize))
    }

    private func handleLoadProfile(_ url: URL, _ deeplinkurl: DeeplinkURL) {
        guard let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 else { return }
        let profile = queryitems[0].value
        guard deeplinkurl.validateProfile(profile, rsyncUIdata.validprofiles) else { return }
        if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == profile }) {
            selectedprofileID = rsyncUIdata.validprofiles[index].id
        }
    }

    private func handleLoadProfileAndEstimate(_ url: URL, _ deeplinkurl: DeeplinkURL, _ externalURL: Bool) {
        guard let queryitems = deeplinkurl.handleURL(url)?.queryItems, queryitems.count == 1 else { return }
        let profile = queryitems[0].value

        selectedview = .synchronize

        if profile == "Default" || profile == "default" {
            handleDefaultProfileEstimate(queryitems, externalURL)
        } else if deeplinkurl.validateProfile(profile, rsyncUIdata.validprofiles), let profile {
            handleNamedProfileEstimate(profile, queryitems, externalURL)
        }
    }

    private func handleDefaultProfileEstimate(_ queryitems: [URLQueryItem], _ externalURL: Bool) {
        Task {
            if externalURL {
                async let loadprofile = loadProfileForExternalURLLink(nil)
                guard await loadprofile else { return }
            }
            if let count = rsyncUIdata.configurations?.count, count > 0 {
                queryitem = queryitems[0]
            }
        }
    }

    private func handleNamedProfileEstimate(_ profile: String, _ queryitems: [URLQueryItem], _ externalURL: Bool) {
        Task {
            if externalURL {
                async let loadprofile = loadProfileForExternalURLLink(profile)
                guard await loadprofile else { return }
            }
            if let count = rsyncUIdata.configurations?.count, count > 0 {
                queryitem = queryitems[0]
            }
        }
    }

    func observerDidMountNotification() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didMountNotification,
                                       object: nil, queue: .main) { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                Task {
                    guard await tasksAreInProgress() == false else { return }
                    await verifyAndLoadProfileMountedVolume(volumeURL)
                }
            }
        }
    }

    func observerDidUnmountNotification() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification,
                                       object: nil, queue: .main) { _ in
            Task {
                guard await tasksAreInProgress() == false else { return }
                await verifyAndLoadProfileMountedVolume(nil)
            }
        }
    }

    private func verifyAndLoadProfileMountedVolume(_ mountedvolume: URL?) async {
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
    private func tasksAreInProgress() async -> Bool {
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
    func loadProfileForExternalURLLink(_ profile: String?) async -> Bool {
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
                                                   SharedReference.shared.rsyncversion3)

        if rsyncUIdata.configurations == nil {
            return false
        } else {
            return true
        }
    }
}
