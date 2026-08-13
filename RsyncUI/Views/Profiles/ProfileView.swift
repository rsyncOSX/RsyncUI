//
//  ProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2024.
//

import OSLog
import SwiftUI

struct ProfileView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?

    @State private var newdata = ObservableProfiles()
    @State private var uuidprofile: ProfilesnamesRecord.ID?
    @State private var newprofile: String = ""

    @State private var allconfigurations: [SynchronizeConfiguration] = []

    @State private var confirmdelete: Bool = false
    @State private var showAddProfileSheet: Bool = false
    @FocusState private var profileTableIsFocused: Bool

    var body: some View {
        VStack {
            HStack {
                Table(rsyncUIdata.validprofiles, selection: $uuidprofile) {
                    TableColumn("Profiles") { name in
                        Text(name.profilename)
                    }
                }
                .frame(width: 300)
                .focused($profileTableIsFocused)
                .onAppear {
                    profileTableIsFocused = true
                }
                .onDeleteCommand {
                    requestProfileDeletion()
                }

                VStack(alignment: .leading) {
                    ProfilesToUpdateView(allconfigurations: allconfigurations)

                    if uuidprofile != nil {
                        ConfigurationsTableLoadDataView(rsyncUIdata: rsyncUIdata, uuidprofile: $uuidprofile)
                    }
                }
            }
        }
        .onSubmit {
            createProfile()
        }
        .toolbar {
            
            ToolbarItem(placement: .status) {
                Button("Add Profile", systemImage: "plus", action: {
                    showAddProfileSheet = true
                })
                .labelStyle(.iconOnly)
                .help("Add Profile")
            }
        }
        .confirmationDialog("Delete profile: \(selectedProfile?.profilename ?? "")?",
                            isPresented: $confirmdelete) {
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
        }
        .sheet(isPresented: $showAddProfileSheet) {
            AddProfileSheet(rsyncUIdata: rsyncUIdata,
                            selectedprofileID: $selectedprofileID,
                            showSheet: $showAddProfileSheet,
                            newdata: newdata)
        }
        .task {
            allconfigurations = await ReadAllTasks().readAllMarkedTasks(rsyncUIdata.validprofiles)
        }
        .navigationTitle("Manage Profiles")
    }
}

extension ProfileView {
    private var selectedProfile: ProfilesnamesRecord? {
        rsyncUIdata.validprofiles.first { $0.id == uuidprofile }
    }

    private func requestProfileDeletion() {
        guard selectedProfile != nil else { return }
        confirmdelete = true
    }

    func createProfile() {
        if newdata.createProfile(newprofile) {
            // Add a profile record
            rsyncUIdata.validprofiles.append(ProfilesnamesRecord(newprofile))
            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == newprofile }) {
                // Set the profile picker and let the picker do the job
                selectedprofileID = rsyncUIdata.validprofiles[index].id
            }
            newprofile = ""
        }
    }

    func deleteProfile() {
        if let profile = selectedProfile {
            if newdata.deleteProfile(profile.profilename) {
                if selectedprofileID == profile.id {
                    selectedprofileID = nil
                }
                // Remove the profile record
                if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == profile.id }) {
                    rsyncUIdata.validprofiles.remove(at: index)
                    uuidprofile = nil
                }
            }
        }
    }
}

// MARK: - Add Profile Sheet

struct AddProfileSheet: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofileID: ProfilesnamesRecord.ID?
    @Binding var showSheet: Bool
    var newdata: ObservableProfiles

    @State private var profileName: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Profile")
                .font(.title2)

            TextField("Profile Name", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            if showError {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(24)
        .frame(width: 400)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    addProfile()
                    showSheet = false
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showSheet = false
                }
            }
        }
    }

    private func addProfile() {
        let trimmedName = profileName.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Profile name cannot be empty"
            showError = true
            return
        }

        if newdata.createProfile(trimmedName) {
            // Add a profile record
            rsyncUIdata.validprofiles.append(ProfilesnamesRecord(trimmedName))
            if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.profilename == trimmedName }) {
                // Set the profile picker and let the picker do the job
                selectedprofileID = rsyncUIdata.validprofiles[index].id
            }
            showSheet = false
        } else {
            errorMessage = "Failed to create profile. It may already exist."
            showError = true
        }
    }
}
