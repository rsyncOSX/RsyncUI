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
    @Binding var selectedprofile: String?

    @State private var newdata = ObservableProfiles()
    @State private var uuidprofile = Set<ProfilesnamesRecord.ID>()
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""

    var body: some View {
        VStack {
            HStack {
                Table(profilenames, selection: $uuidprofile) {
                    TableColumn("Profiles") { name in
                        Text(name.profilename ?? "Default profile")
                    }
                }
                .onChange(of: uuidprofile) {
                    /*
                    let profile = profilenames.profiles?.filter { profiles in
                        uuidprofile.contains(profiles.id)
                    }
                    if profile?.count == 1 {
                        localselectedprofile = profile?[0].profile
                    }
                     */
                }
                /*
                 if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                     hiddenID = configurations[index].hiddenID
                 }
                 */

                // ProfilesToUpdataView(allprofiles: rsyncUIdata.validprofiles)
            }

            EditValue(150, NSLocalizedString("Create profile", comment: ""),
                      $newprofile)
        }
        .onSubmit {
            createprofile()
        }
        .navigationTitle("Profile create or delete")
        .toolbar {
            ToolbarItem {
                Button {
                    guard newprofile.isEmpty == false else { return }
                    createprofile()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Add profile")
            }

            ToolbarItem {
                Button {
                    guard localselectedprofile?.isEmpty == false else { return }
                    newdata.showAlertfordelete = true
                } label: {
                    Image(systemName: "trash.fill")
                }
                .help("Delete profile")
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(delete: $newdata.confirmdeleteselectedprofile,
                                             profile: localselectedprofile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }
            }
        }
    }

    var profilenames: [ProfilesnamesRecord] {
        if let allprofiles = Profilenames(rsyncUIdata.validprofiles).profiles {
            return allprofiles
        } else {
            return []
        }
    }
}

extension ProfileView {
    func createprofile() {
        newdata.createprofile(newprofile: newprofile)
        // profilenames.update(rsyncUIdata.validprofiles ?? [])
        selectedprofile = newdata.selectedprofile
        rsyncUIdata.validprofiles = nil
        rsyncUIdata.profile = selectedprofile
        newprofile = ""
    }

    func deleteprofile() {
        newdata.deleteprofile(localselectedprofile)
        // profilenames.update(rsyncUIdata.validprofiles ?? [])
        selectedprofile = SharedReference.shared.defaultprofile
        // Must fix
        rsyncUIdata.validprofiles = nil
        rsyncUIdata.profile = SharedReference.shared.defaultprofile
    }
}
