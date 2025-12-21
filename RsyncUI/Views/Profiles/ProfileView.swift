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
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""

    @State private var allconfigurations: [SynchronizeConfiguration] = []

    @State private var confirmdelete: Bool = false

    var body: some View {
        VStack {
            HStack {
                Table(rsyncUIdata.validprofiles, selection: $uuidprofile) {
                    TableColumn("Profiles") { name in
                        Text(name.profilename)
                    }
                }
                .onChange(of: uuidprofile) {
                    let record = rsyncUIdata.validprofiles.filter { $0.id == uuidprofile }
                    guard record.count > 0 else {
                        localselectedprofile = nil
                        return
                    }
                    localselectedprofile = record[0].profilename
                }
                .frame(width: 300)
                .onDeleteCommand {
                    confirmdelete = true
                }
                .confirmationDialog("Delete profile: \(localselectedprofile ?? "")?",
                                    isPresented: $confirmdelete) {
                    Button("Delete", role: .destructive) {
                        deleteProfile()
                    }
                }

                VStack(alignment: .leading) {
                    ProfilesToUpdateView(allconfigurations: allconfigurations)

                    if uuidprofile != nil {
                        ConfigurationsTableLoadDataView(rsyncUIdata: rsyncUIdata, uuidprofile: $uuidprofile)
                    }
                }
            }

            EditValueScheme(300, "Create profile - press Enter when added",
                            $newprofile)
        }
        .onSubmit {
            createProfile()
        }
        .task {
            allconfigurations = await ReadAllTasks().readAllMarkedTasks(rsyncUIdata.validprofiles)
        }
        .navigationTitle("Profile create or delete")
    }
}

extension ProfileView {
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
        if let deleteprofile = localselectedprofile {
            if newdata.deleteProfile(deleteprofile) {
                selectedprofileID = nil
                // Remove the profile record
                if let index = rsyncUIdata.validprofiles.firstIndex(where: { $0.id == uuidprofile }) {
                    rsyncUIdata.validprofiles.remove(at: index)
                    uuidprofile = nil
                }
            }
        }
    }
}
