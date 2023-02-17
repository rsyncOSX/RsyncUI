//
//  OneConfigUUID.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct OneConfigProgressView: View {
    @EnvironmentObject var executedetails: InprogressCountExecuteOneTaskDetails
    @Binding var selecteduuids: Set<UUID>
    @Binding var inwork: Int

    var config: Configuration

    var body: some View {
        HStack {
            if selecteduuids.count > 0 { progress }
            OneConfig(forestimated: false,
                      config: config)
        }
    }

    var progress: some View {
        ZStack {
            if config.hiddenID == inwork && executedetails.isestimating() == false {
                ZStack {
                    ProgressView("",
                                 value: executedetails.getcurrentprogress(),
                                 total: maxcount)
                        .onChange(of: executedetails.getcurrentprogress(), perform: { _ in })
                        .frame(width: 40, alignment: .center)

                    Text(String(Int(maxcount - executedetails.getcurrentprogress())))
                        .modifier(FixedTag(20, .leading))
                        .opacity(0.5)
                }

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

    var maxcount: Double {
        return executedetails.getmaxcountbytask(inwork)
    }
}
