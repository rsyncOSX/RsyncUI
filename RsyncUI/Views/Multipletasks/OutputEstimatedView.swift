//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
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
                                Text(Image(systemName: "arrowtriangle.right"))
                                    .modifier(FixedTag(25, .leading))
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

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1100, minHeight: 400)
    }

    var headingtitle: some View {
        Text("Estimated tasks")
            .font(.title2)
            .padding()
    }

    var header: some View {
        HStack {
            Group {
                Text("")
                    .modifier(FixedTag(95, .center))
                Text("Synchronize ID")
                    .modifier(FixedTag(120, .center))
                Text("Task")
                    .modifier(FixedTag(80, .center))
                Text("Local catalog")
                    .modifier(FlexTag(200, .center))
                Text("Remote catalog")
                    .modifier(FlexTag(180, .center))
                Text("Server")
                    .modifier(FixedTag(80, .trailing))
                Text("User")
                    .modifier(FixedTag(80, .trailing))
            }
            Group {
                Text("New")
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text("Delete")
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text("Files")
                    .modifier(FixedTag(40, .trailing))
                    .foregroundColor(Color.red)
                Text("Bytes")
                    .modifier(FixedTag(80, .trailing))
                    .foregroundColor(Color.red)
                Text("Tot num")
                    .modifier(FixedTag(80, .trailing))
                Text("Tot bytes")
                    .modifier(FixedTag(80, .trailing))
                Text("Tot dir")
                    .modifier(FixedTag(80, .trailing))
            }
        }
    }

    func dismissview() {
        isPresented = false
    }
}
