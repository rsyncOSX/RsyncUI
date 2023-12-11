//
//  NavigationAddProfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/12/2023.
//

import SwiftUI

struct NavigationAddProfileView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var newdata = ObservableAddConfigurations()
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool
    @State private var uuidprofile = Set<Profiles.ID>()

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
                    selectedprofile = profile[0].profile
                }
            }

            Spacer()

            HStack {
                HStack {
                    Button("Create") { createprofile() }
                        .buttonStyle(ColorfulButtonStyle())

                    EditValue(150, NSLocalizedString("Create profile", comment: ""),
                              $newdata.newprofile)
                }

                Button("Delete") { newdata.showAlertfordelete = true }
                    .buttonStyle(ColorfulRedButtonStyle())
                    .sheet(isPresented: $newdata.showAlertfordelete) {
                        ConfirmDeleteProfileView(delete: $newdata.confirmdeleteselectedprofile,
                                                 profile: rsyncUIdata.profile)
                            .onDisappear(perform: {
                                deleteprofile()
                            })
                    }
            }
        }
        .onSubmit {
            createprofile()
        }
        .alert(isPresented: $newdata.alerterror,
               content: { Alert(localizedError: newdata.error)
               })
    }
}

extension NavigationAddProfileView {
    func createprofile() {
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
