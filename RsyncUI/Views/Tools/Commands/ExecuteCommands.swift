//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//

import SwiftUI

struct ExecuteCommands: Commands {
    @FocusedBinding(\.startestimation) private var startestimation
    @FocusedBinding(\.startexecution) private var startexecution
    @FocusedBinding(\.firsttaskinfo) private var firsttaskinfo
    @FocusedBinding(\.showinfotask) private var showinfotask
    @FocusedBinding(\.aborttask) private var aborttask
    @FocusedBinding(\.enabletimer) private var enabletimer

    var body: some Commands {
        CommandMenu("Tasks") {
            StarteestimateButton(startestimation: $startestimation)
            StartexecuteButton(startexecution: $startexecution)

            Divider()

            FirsttaskInfo(firsttaskinfo: $firsttaskinfo)
            Showinfotask(showinfotask: $showinfotask)

            Divider()

            Enabletimer(enabletimer: $enabletimer)

            Divider()

            Abborttask(aborttask: $aborttask)
        }
    }
}

struct StarteestimateButton: View {
    @Binding var startestimation: Bool?

    var body: some View {
        Button {
            startestimation = true
        } label: {
            Label("Estimate", systemImage: "play.fill")
        }
        .keyboardShortcut("e", modifiers: [.command])
    }
}

struct StartexecuteButton: View {
    @Binding var startexecution: Bool?

    var body: some View {
        Button {
            startexecution = true
        } label: {
            Label("Synchronize", systemImage: "play.fill")
        }
        .keyboardShortcut("r", modifiers: [.command])
    }
}

struct SelectTask: View {
    @Binding var selecttask: Bool?

    var body: some View {
        Button {
            selecttask = true
        } label: {
            Label("Select task", systemImage: "play.fill")
        }
        .keyboardShortcut("s", modifiers: [.command])
    }
}

struct FirsttaskInfo: View {
    @Binding var firsttaskinfo: Bool?

    var body: some View {
        Button {
            firsttaskinfo = true
        } label: {
            Label("First task", systemImage: "play.fill")
        }
        .keyboardShortcut("f", modifiers: [.command])
    }
}

struct Showinfotask: View {
    @Binding var showinfotask: Bool?

    var body: some View {
        Button {
            showinfotask = true
        } label: {
            Label("Show info", systemImage: "play.fill")
        }
        .keyboardShortcut("i", modifiers: [.command])
    }
}

struct Abborttask: View {
    @Binding var aborttask: Bool?

    var body: some View {
        Button {
            aborttask = true
        } label: {
            Label("Abort task", systemImage: "play.fill")
        }
        .keyboardShortcut("k", modifiers: [.command])
    }
}

struct Enabletimer: View {
    @Binding var enabletimer: Bool?

    var body: some View {
        Button {
            enabletimer = true
        } label: {
            Label("Timer", systemImage: "play.fill")
        }
        // .keyboardShortcut("", modifiers: [.command])
    }
}

struct FocusedEstimateBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedExecuteBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedFirsttaskInfo: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedShowinfoTask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedAborttask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedEnabletimer: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var startestimation: FocusedEstimateBinding.Value? {
        get { self[FocusedEstimateBinding.self] }
        set { self[FocusedEstimateBinding.self] = newValue }
    }

    var startexecution: FocusedExecuteBinding.Value? {
        get { self[FocusedExecuteBinding.self] }
        set { self[FocusedExecuteBinding.self] = newValue }
    }

    var firsttaskinfo: FocusedFirsttaskInfo.Value? {
        get { self[FocusedFirsttaskInfo.self] }
        set { self[FocusedFirsttaskInfo.self] = newValue }
    }

    var showinfotask: FocusedShowinfoTask.Value? {
        get { self[FocusedShowinfoTask.self] }
        set { self[FocusedShowinfoTask.self] = newValue }
    }

    var aborttask: FocusedAborttask.Value? {
        get { self[FocusedAborttask.self] }
        set { self[FocusedAborttask.self] = newValue }
    }

    var enabletimer: FocusedAborttask.Value? {
        get { self[FocusedEnabletimer.self] }
        set { self[FocusedEnabletimer.self] = newValue }
    }
}
