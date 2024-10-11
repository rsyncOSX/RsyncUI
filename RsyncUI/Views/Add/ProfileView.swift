//
//  ProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 09/05/2024.
//

import SwiftUI

struct ProfileView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableProfiles()
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var uuidprofile = Set<ProfilesnamesRecord.ID>()
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""
    // Update pressed
    @State var updated: Bool = false
    // Some not updated profiles
    @State private var notupdatedprofiles: Bool = false

    var body: some View {
        VStack {
            Table(profilenames.profiles ?? [], selection: $uuidprofile) {
                TableColumn("Profiles") { name in
                    Text(name.profile ?? "Default profile")
                }
            }
            .onChange(of: uuidprofile) {
                let profile = profilenames.profiles?.filter { profiles in
                    uuidprofile.contains(profiles.id)
                }
                if profile?.count == 1 {
                    localselectedprofile = profile?[0].profile
                }
                updated = false
            }

            Spacer()

            if notupdatedprofiles {
                Text("Some old profiles")
            }

            EditValue(150, NSLocalizedString("Create profile", comment: ""),
                      $newprofile)
        }
        .onAppear(perform: {
            readalltasks()
        })
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

    var allprofiles: [String]? {
        Homepath().getfullpathmacserialcatalogsasstringnames()
    }

    private func readalltasks() {
        for i in 0 ..< (allprofiles?.count ?? 0) {
            var profilename = allprofiles?[i]
            if profilename == "Default profile" {
                profilename = nil
            }
            let configurations = ReadSynchronizeConfigurationJSON(profilename).configurations
            let old = configurations?.filter { element in
                var seconds: Double {
                    if let date = element.dateRun {
                        let lastbackup = date.en_us_date_from_string()
                        return lastbackup.timeIntervalSinceNow * -1
                    } else {
                        return 0
                    }
                }
                return markconfig(seconds) == true
            }
            notupdatedprofiles = (old?.count ?? 0) > 0 ? false : true
        }
    }

    private func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
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
