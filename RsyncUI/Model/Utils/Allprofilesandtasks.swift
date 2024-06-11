//
//  Allprofilesandtasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//

class Allprofilesandtasks {
    // Configurations object
    var alltasks: [SynchronizeConfiguration]?
    var allprofiles: [String]?

    private func getprofilenames() {
        allprofiles = Homepath().getcatalogsasstringnames()
    }

    private func readalltasks() {
        var configurations: [SynchronizeConfiguration]?
        for i in 0 ..< (allprofiles?.count ?? 0) {
            let profilename = allprofiles?[i]
            if alltasks == nil { alltasks = [] }
            if profilename == "Default profile" {
                configurations = ReadConfigurationJSON(nil).configurations
            } else {
                configurations = ReadConfigurationJSON(profilename).configurations
            }
            for j in 0 ..< (configurations?.count ?? 0) {
                configurations?[j].profile = profilename
                if let configuration = configurations?[j] {
                    alltasks?.append(configuration)
                }
            }
        }
    }

    init() {
        getprofilenames()
        readalltasks()
    }
}
