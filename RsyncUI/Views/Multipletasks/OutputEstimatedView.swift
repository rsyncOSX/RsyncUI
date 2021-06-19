//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var isPresented: Bool
    @Binding var selecteduuids: Set<UUID>
    var estimatedlist: [RemoteinfonumbersOnetask]

    let forestimated = true

    var body: some View {
        VStack {
            headingtitle

            Section(header: header) {
                List {
                    ForEach(estimatedlist) { estimatedconfiguration in
                        HStack {
                            if selecteduuids.contains(estimatedconfiguration.config!.id) {
                                Text(Image(systemName: "arrowtriangle.right.fill"))
                                    .modifier(FixedTag(25, .leading))
                                    .foregroundColor(.green)
                            } else {
                                Text("")
                                    .modifier(FixedTag(25, .leading))
                            }
                            if let configuration = estimatedconfiguration.config {
                                OneConfig(forestimated: forestimated,
                                          config: configuration)
                            }
                            HStack {
                                Text(estimatedconfiguration.newfiles)
                                    .modifier(FixedTag(40, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.deletefiles)
                                    .modifier(FixedTag(40, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.transferredNumber)
                                    .modifier(FixedTag(40, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.transferredNumberSizebytes)
                                    .modifier(FixedTag(80, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.totalNumber)
                                    .modifier(FixedTag(80, .trailing))
                                Text(estimatedconfiguration.totalNumberSizebytes)
                                    .modifier(FixedTag(80, .trailing))
                                Text(estimatedconfiguration.totalDirs)
                                    .modifier(FixedTag(80, .trailing))
                            }
                        }
                    }
                    .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
            }
            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1100, minHeight: 400)
    }

    var headingtitle: some View {
        Text(NSLocalizedString("Estimated tasks", comment: "RsyncCommandView"))
            .font(.title2)
            .padding()
    }

    var header: some View {
        HStack {
            Group {
                Text("")
                    .modifier(FixedTag(95, .center))
                Text(NSLocalizedString("Synchronize ID", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(120, .center))
                Text(NSLocalizedString("Task", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .center))
                Text(NSLocalizedString("Local catalog", comment: "OutputEstimatedView"))
                    .modifier(FlexTag(200, .center))
                Text(NSLocalizedString("Remote catalog", comment: "OutputEstimatedView"))
                    .modifier(FlexTag(180, .center))
                Text(NSLocalizedString("Server", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
                Text(NSLocalizedString("User", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
            }
            Group {
                Text(NSLocalizedString("New", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text(NSLocalizedString("Delete", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text(NSLocalizedString("Files", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text(NSLocalizedString("Bytes", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
                    .foregroundColor(Color.red)
                Text(NSLocalizedString("Tot num", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
                Text(NSLocalizedString("Tot bytes", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
                Text(NSLocalizedString("Tot dir", comment: "OutputEstimatedView"))
                    .modifier(FixedTag(80, .trailing))
            }
        }
    }

    func dismissview() {
        isPresented = false
    }
}
