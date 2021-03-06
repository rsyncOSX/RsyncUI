//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata

    @Binding var isPresented: Bool
    @Binding var estimatedlist: [RemoteinfonumbersOnetask]?
    @Binding var selecteduuids: Set<UUID>
    @State private var forestimated = true

    var estimatedoutput: [RemoteinfonumbersOnetask] {
        return estimatedlist ?? []
    }

    var body: some View {
        VStack {
            Section(header: header) {
                List {
                    ForEach(estimatedoutput) { estimatedconfiguration in
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
                                OneConfig(forestimated: $forestimated,
                                          config: configuration)
                            }
                            HStack {
                                Text(estimatedconfiguration.newfiles ?? "0")
                                    .modifier(FixedTag(35, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.deletefiles ?? "0")
                                    .modifier(FixedTag(35, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.transferredNumber ?? "0")
                                    .modifier(FixedTag(35, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.transferredNumberSizebytes ?? "0")
                                    .modifier(FixedTag(80, .trailing))
                                    .foregroundColor(Color.red)
                                Text(estimatedconfiguration.totalNumber ?? "0")
                                    .modifier(FixedTag(80, .trailing))
                                Text(estimatedconfiguration.totalNumberSizebytes ?? "0")
                                    .modifier(FixedTag(80, .trailing))
                                Text(estimatedconfiguration.totalDirs ?? "0")
                                    .modifier(FixedTag(35, .trailing))
                            }
                        }
                    }
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

    var header: some View {
        HStack {
            Group {
                Text("")
                    .modifier(FixedTag(95, .center))
                Text(NSLocalizedString("Synchronizing ID", comment: "OutputEstimatedView"))
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
                    .modifier(FixedTag(35, .trailing))
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

struct DarkBlueShadowProgressViewStyle: ProgressViewStyle {
    typealias ProgressViewStyle = ProgressViewStyleConfiguration

    func makeBody(configuration: ProgressViewStyle) -> some View {
        ProgressView(configuration)
            .shadow(color: Color(red: 0, green: 0, blue: 0.6),
                    radius: 4.0, x: 1.0, y: 2.0)
    }
}
