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
    @Binding var inwork: Int

    let forestimated = false
    var config: Configuration

    var body: some View {
        HStack {
            progress

            OneConfig(forestimated: forestimated,
                      config: config)
        }
    }

    var progress: some View {
        ZStack {
            if config.hiddenID == inwork && executedetails.isestimating() == false {
                progressexecution
            } else {
                Text("")
                    .modifier(FixedTag(20, .leading))
            }
            if selecteduuids.contains(config.id) && config.hiddenID != inwork {
                Text(Image(systemName: "arrowtriangle.right"))
                    .modifier(FixedTag(20, .leading))
            } else {
                Text("")
                    .modifier(FixedTag(20, .leading))
            }
        }
        .frame(width: 40, alignment: .center)
    }

    // Progressview for execute estimated tasks
    var progressexecution: some View {
        ProgressView("",
                     value: executedetails.getcurrentprogress(),
                     total: executedetails.getmaxcountbytask(inwork))
            .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
            .frame(width: 40, alignment: .center)
    }
}
