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
    @FocusedBinding(\.selecttask) private var selectttask
    @FocusedBinding(\.firsttaskinfo) private var firsttaskinfo
    @FocusedBinding(\.deletetask) private var deletetask
    @FocusedBinding(\.showinfotask) private var showinfotask
    @FocusedBinding(\.aborttask) private var aborttask
    @FocusedBinding(\.profiletask) private var profiletask

    var body: some Commands {
        CommandMenu("Tasks") {
            Group {
                StarteestimateButton(startestimation: $startestimation)
                StartexecuteButton(startexecution: $startexecution)

                Divider()

                SelectTask(selecttask: $selectttask)
                FirsttaskInfo(firsttaskinfo: $firsttaskinfo)
                Showinfotask(showinfotask: $showinfotask)

                Divider()
            }

            Group {
                Deletetask(deletetask: $deletetask)
                Profiletask(profiletask: $profiletask)

                Divider()

                Abborttask(aborttask: $aborttask)
            }
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
            Label("Execute", systemImage: "play.fill")
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

struct Deletetask: View {
    @Binding var deletetask: Bool?

    var body: some View {
        Button {
            deletetask = true
        } label: {
            Label("Delete task", systemImage: "trash.fill")
        }
        .keyboardShortcut("d", modifiers: [.command])
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
        .keyboardShortcut("a", modifiers: [.command])
    }
}

struct Profiletask: View {
    @Binding var profiletask: Bool?

    var body: some View {
        Button {
            profiletask = true
        } label: {
            Label("Profiles", systemImage: "play.fill")
        }
        .keyboardShortcut("p", modifiers: [.command])
    }
}

struct FocusedEstimateBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedExecuteBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedSelecttask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedFirsttaskInfo: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedDeletetask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedShowinfoTask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedAborttask: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedProfiletask: FocusedValueKey {
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

    var selecttask: FocusedSelecttask.Value? {
        get { self[FocusedSelecttask.self] }
        set { self[FocusedSelecttask.self] = newValue }
    }

    var firsttaskinfo: FocusedFirsttaskInfo.Value? {
        get { self[FocusedFirsttaskInfo.self] }
        set { self[FocusedFirsttaskInfo.self] = newValue }
    }

    var deletetask: FocusedDeletetask.Value? {
        get { self[FocusedDeletetask.self] }
        set { self[FocusedDeletetask.self] = newValue }
    }

    var showinfotask: FocusedShowinfoTask.Value? {
        get { self[FocusedShowinfoTask.self] }
        set { self[FocusedShowinfoTask.self] = newValue }
    }

    var aborttask: FocusedAborttask.Value? {
        get { self[FocusedAborttask.self] }
        set { self[FocusedAborttask.self] = newValue }
    }

    var profiletask: FocusedAborttask.Value? {
        get { self[FocusedProfiletask.self] }
        set { self[FocusedProfiletask.self] = newValue }
    }
}
