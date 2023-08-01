//
//  AddProfile.swift
//  AddProfile
//
//  Created by Thomas Evensen on 04/09/2021.
//

import SwiftUI

struct AddProfileView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @SwiftUI.Environment(Profilenames.self) private var profilenames
    @State private var newdata = ObservableAddConfigurations()

    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var uuidprofile = Set<Profiles.ID>()

    var body: some View {
        ZStack {
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

                VStack(alignment: .leading) {
                    HStack {
                        Text("Selected profile:")
                        Text(rsyncUIdata.profile ?? SharedReference.shared.defaultprofile)
                            .foregroundColor(Color.blue)
                    }

                    HStack {
                        Button("Create") { createprofile() }
                            .buttonStyle(PrimaryButtonStyle())

                        EditValue(150, NSLocalizedString("Create profile", comment: ""),
                                  $newdata.newprofile)
                    }
                }

                Spacer()
            }
        }

        Spacer()

        HStack {
            Spacer()

            Button("Dismiss") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())

            Button("Delete") { newdata.showAlertfordelete = true }
                .buttonStyle(AbortButtonStyle())
                .sheet(isPresented: $newdata.showAlertfordelete) {
                    ConfirmDeleteProfileView(delete: $newdata.confirmdeleteselectedprofile,
                                             profile: rsyncUIdata.profile)
                        .onDisappear(perform: {
                            deleteprofile()
                        })
                }
        }
        .padding()
        .onSubmit {
            createprofile()
        }
        .alert(isPresented: $newdata.alerterror,
               content: { Alert(localizedError: newdata.error)
               })
    }
}

extension AddProfileView {
    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
        dismiss()
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
        dismiss()
    }
}
