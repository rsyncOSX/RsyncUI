//
//  TimerView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/12/2024.
//

import Combine
import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var executetaskpath: [Tasks]

    @State private var countdown: SynchronizationCountdown?
    @State private var remainingSeconds = 6

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            countdown?.cancel()
            dismiss()
        } label: {
            Text(String(remainingSeconds))
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .font(.title2)
        }
        .help("Cancel synchronization")
        .accessibilityLabel("Cancel synchronization")
        .accessibilityValue("\(remainingSeconds) seconds remaining")
        .onAppear {
            let now = Date.now
            countdown = SynchronizationCountdown(
                start: now,
                withoutTimeDelay: SharedReference.shared.synchronizewithouttimedelay
            )
            updateCountdown(at: now)
        }
        .onReceive(timer) { date in
            updateCountdown(at: date)
        }
        .onDisappear {
            countdown?.cancel()
        }
    }

    private func updateCountdown(at date: Date) {
        guard let countdown else { return }
        remainingSeconds = countdown.remainingSeconds(at: date)
        if self.countdown?.consumeExpiration(at: date) == true {
            executetaskpath = [Tasks(task: .executestimatedview)]
        }
    }
}

struct SynchronizationCountdown {
    private let deadline: Date
    private var isActive = true

    init(start: Date, withoutTimeDelay: Bool) {
        deadline = start.addingTimeInterval(withoutTimeDelay ? 0 : 6)
    }

    func remainingSeconds(at date: Date) -> Int {
        Int(max(0, deadline.timeIntervalSince(date)).rounded(.up))
    }

    mutating func consumeExpiration(at date: Date) -> Bool {
        guard isActive, date >= deadline else { return false }
        isActive = false
        return true
    }

    mutating func cancel() {
        isActive = false
    }
}
