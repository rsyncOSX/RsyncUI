//
//  OneConfigUUID.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct OneConfigUUID: View {
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var inexecuting: Int
    @State private var forestimated = false
    var config: Configuration

    var body: some View {
        HStack {
            progress

            OneConfig(forestimated: $forestimated, config: config)
        }
    }

    var progress: some View {
        HStack {
            if config.hiddenID == inexecuting && executedetails.isestimating() {
                progressview
            } else if config.hiddenID == inexecuting {
                progressexecution
            } else {
                Text("")
                    .modifier(FixedTag(20, .leading))
            }
            if selecteduuids.contains(config.id) && config.hiddenID != inexecuting {
                Text(Image(systemName: "arrowtriangle.right.fill"))
                    .modifier(FixedTag(20, .leading))
                    .foregroundColor(.green)
            } else {
                Text("")
                    .modifier(FixedTag(20, .leading))
            }
        }
    }

    // Progressview for estimating and execute tasks without estimation
    var progressview: some View {
        ProgressView()
    }

    // Progressview for execute estimated tasks
    var progressexecution: some View {
        ProgressView("",
                     value: executedetails.getcurrentprogress(),
                     total: executedetails.getmaxcountbytask(inexecuting))
            .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
            .frame(width: 50, height: nil, alignment: .center)
    }
}
