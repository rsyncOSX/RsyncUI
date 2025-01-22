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
    @State private var uuidprofile: ProfilesnamesRecord.ID?
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""
    
    @State private var isPresentingConfirm: Bool = false

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
                    guard record.count > 0 else { return }
                    localselectedprofile = record[0].profilename
                }

                ProfilesToUpdataView(allprofiles: rsyncUIdata.validprofiles)
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
                    isPresentingConfirm = (localselectedprofile?.isEmpty == false && localselectedprofile != SharedReference.shared.defaultprofile)
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Delete profile")
                .confirmationDialog("Delete \(localselectedprofile ?? "")?",
                                    isPresented: $isPresentingConfirm)
                {
                    Button("Delete", role: .destructive) {
                        deleteprofile()
                    }
                }
            }
        }
    }
}

extension ProfileView {
    func createprofile() {
        newdata.createprofile(newprofile: newprofile)
        selectedprofile = newdata.selectedprofile
        rsyncUIdata.validprofiles.removeAll()
        rsyncUIdata.profile = selectedprofile
        newprofile = ""
    }

    func deleteprofile() {
        newdata.deleteprofile(localselectedprofile)
        selectedprofile = SharedReference.shared.defaultprofile
        rsyncUIdata.validprofiles.removeAll()
        rsyncUIdata.profile = SharedReference.shared.defaultprofile
    }
}
