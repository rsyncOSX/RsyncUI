//
//  ProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2024.
//

import SwiftUI

struct ProfileView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableAddConfigurations()
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var uuidprofile = Set<ProfilesnamesRecord.ID>()
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""
    // Update pressed
    @State var updated: Bool = false

    var body: some View {
        VStack {
            Table(profilenames.profiles, selection: $uuidprofile) {
                TableColumn("Profiles") { name in
                    Text(name.profile ?? "Default profile")
                }
            }
            .onChange(of: uuidprofile) {
                let profile = profilenames.profiles.filter { profiles in
                    uuidprofile.contains(profiles.id)
                }
                if profile.count == 1 {
                    localselectedprofile = profile[0].profile
                }
                updated = false
            }

            Spacer()

            EditValue(150, NSLocalizedString("Create profile", comment: ""),
                      $newprofile)
        }
        .onSubmit {
            createprofile()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    guard newprofile.isEmpty == false else { return }
                    createprofile()
                } label: {
                    if updated == false {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color(.blue))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.blue))
                    }
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
}

extension ProfileView {
    func createprofile() {
        newdata.createprofile(newprofile: newprofile)
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        rsyncUIdata.profile = selectedprofile
        newprofile = ""
        updated = true
    }

    func deleteprofile() {
        newdata.deleteprofile(localselectedprofile)
        profilenames.update()
        selectedprofile = SharedReference.shared.defaultprofile
        rsyncUIdata.profile = SharedReference.shared.defaultprofile
    }
}
