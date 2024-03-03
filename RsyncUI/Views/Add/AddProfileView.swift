//
//  AddProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import SwiftUI

struct AddProfileView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableAddConfigurations()
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var uuidprofile = Set<Profiles.ID>()
    @State private var localselectedprofile: String?
    @State private var newprofile: String = ""

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
            }

            Spacer()

            EditValue(150, NSLocalizedString("Create profile", comment: ""),
                      $newprofile)
        }
        .onSubmit {
            createprofile()
        }
        .alert(isPresented: $newdata.alerterror,
               content: { Alert(localizedError: newdata.error)
               })
        .toolbar {
            ToolbarItem {
                Button {
                    createprofile()
                } label: {
                    Image(systemName: "return")
                        .foregroundColor(Color(.blue))
                }
                .help("Add profile")
            }

            ToolbarItem {
                Button {
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

extension AddProfileView {
    func createprofile() {
        guard newprofile.isEmpty == false else { return }
        newdata.createprofile(newprofile: newprofile)
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        rsyncUIdata.profile = selectedprofile
    }

    func deleteprofile() {
        newdata.deleteprofile(localselectedprofile)
        profilenames.update()
        selectedprofile = SharedReference.shared.defaultprofile
        rsyncUIdata.profile = SharedReference.shared.defaultprofile
    }
}
