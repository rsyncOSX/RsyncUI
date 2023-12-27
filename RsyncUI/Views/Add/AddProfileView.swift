//
//  AddProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import SwiftUI

struct AddProfileView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var newdata = ObservableAddConfigurations()
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var uuidprofile = Set<Profiles.ID>()
    @State private var localselectedprofile: String?

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
                      $newdata.newprofile)
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
                    Image(systemName: "plus.app.fill")
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
                                             profile: rsyncUIdata.profile)
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
        guard newdata.newprofile != "" else { return }
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
    }
}
