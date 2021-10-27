//
//  AddProfile.swift
//  AddProfile
//
//  Created by Thomas Evensen on 04/09/2021.
//

import AlertToast
import SwiftUI

struct AddProfileView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @EnvironmentObject var profilenames: Profilenames
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @StateObject var newdata = ObserveableAddConfigurations()

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Selected profile:")
                            Text(rsyncUIdata.profile ?? SharedReference.shared.defaultprofile)
                                .foregroundColor(Color.blue)
                        }

                        EditValue(150, NSLocalizedString("Create profile", comment: ""),
                                  $newdata.newprofile)
                    }

                    Spacer()
                }

                if newdata.deletedefaultprofile == true { cannotdeletedefaultprofile }
                if newdata.created == true { notifycreated }
                if newdata.deleted == true { notifydeleted }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Create") { createprofile() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { newdata.showAlertfordelete = true }
                    .buttonStyle(AbortButtonStyle())
                    .sheet(isPresented: $newdata.showAlertfordelete) {
                        ConfirmDeleteProfileView(isPresented: $newdata.showAlertfordelete,
                                                 delete: $newdata.confirmdeleteselectedprofile,
                                                 profile: $rsyncUIdata.profile)
                            .onDisappear(perform: {
                                deleteprofile()
                            })
                    }
            }
            .padding()
            /*
             .onAppear(perform: {
                 if selectedprofile == nil {
                     selectedprofile = SharedReference.shared.defaultprofile
                 }
             })
              */
            .onSubmit {
                createprofile()
            }
        }
    }

    var notifyadded: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Added"), subTitle: Optional(""))
    }

    var notifycreated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Created"), subTitle: Optional(""))
    }

    var notifydeleted: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional("Deleted"), subTitle: Optional(""))
    }

    var cannotdeletedefaultprofile: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional("Cannot delete default profile"), subTitle: Optional(""))
    }
}

extension AddProfileView {
    func createprofile() {
        newdata.createprofile()
        profilenames.update()
        selectedprofile = newdata.selectedprofile
        reload = true
        if newdata.created == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.created = false
            }
        }
    }

    func deleteprofile() {
        newdata.deleteprofile(selectedprofile)
        profilenames.update()
        reload = true
        selectedprofile = nil
        if newdata.deleted == true {
            profilenames.update()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deleted = false
            }
        }
        if newdata.deletedefaultprofile == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newdata.deletedefaultprofile = false
            }
        }
    }
}
