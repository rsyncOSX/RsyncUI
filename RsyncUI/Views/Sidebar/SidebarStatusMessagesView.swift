import SwiftUI

struct SidebarStatusMessagesView: View {
    let newVersionAvailable: Bool
    @Binding var mountingVolumeNow: Bool
    let timerIsActive: Bool
    let nextScheduleText: String
    let showNotExecutedAfterWake: Bool
    let rsyncVersionShort: String
    let clearNotExecutedAfterWake: () -> Void

    var body: some View {
        if newVersionAvailable {
            MessageView(mytext: "New version available\nsee About RsyncUI", size: .caption2)
                .padding([.bottom], -30)
        }

        if mountingVolumeNow {
            MessageView(mytext: "Mounting volume\nplease wait", size: .caption2)
                .padding([.bottom], -30)
                .onAppear {
                    Task {
                        try? await Task.sleep(seconds: 2)
                        mountingVolumeNow = false
                    }
                }
        }

        if timerIsActive {
            MessageView(mytext: nextScheduleText, size: .caption2)
                .padding([.bottom], -30)
        }

        if showNotExecutedAfterWake {
            MessageView(mytext: "Not executed schedules\nafter wakeup", size: .caption2)
                .padding([.bottom], -30)
                .onAppear {
                    Task {
                        try? await Task.sleep(seconds: 5)
                        clearNotExecutedAfterWake()
                    }
                }
        }

        MessageView(mytext: rsyncVersionShort, size: .caption2)
    }
}
