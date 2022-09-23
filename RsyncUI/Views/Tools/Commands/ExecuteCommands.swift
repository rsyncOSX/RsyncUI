//
//  ExecuteCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/06/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct ExecuteCommands: Commands {
    @FocusedBinding(\.startestimation) private var startestimation
    @FocusedBinding(\.startexecution) private var startexecution
    @FocusedBinding(\.selecttask) private var selectttask
    @FocusedBinding(\.firsttaskinfo) private var firsttaskinfo
    @FocusedBinding(\.deletetask) private var deletetask
    @FocusedBinding(\.showinfotask) private var showinfotask
    // @FocusedBinding(\.starttestfortcpconnections) private var starttestfortcpconnections

    var body: some Commands {
        CommandMenu("Tasks") {
            StarteestimateButton(startestimation: $startestimation)
            StartexecuteButton(startexecution: $startexecution)

            Divider()

            SelectTask(selecttask: $selectttask)
            FirsttaskInfo(firsttaskinfo: $firsttaskinfo)
            Showinfotask(showinfotask: $showinfotask)

            Divider()

            Deletetask(deletetask: $deletetask)
            // StartTCPconnectionsButton(starttestfortcpconnections: $starttestfortcpconnections)
        }

        /*
         // **Schedules**
         CommandMenu("Schedules") {
             Button(action: {
                 let running = Running()
                 guard running.informifisrsyncshedulerunning() == false else { return }
                 NSWorkspace.shared.open(URL(fileURLWithPath: (SharedReference.shared.pathrsyncschedule ?? "/Applications/")
                         + SharedReference.shared.namersyncschedule))
                 NSApp.terminate(self)
             }) {
                 Text("Scheduled tasks")
             }
             .keyboardShortcut("s", modifiers: [.command])
         }
         */
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

struct StartTCPconnectionsButton: View {
    @Binding var starttestfortcpconnections: Bool?

    var body: some View {
        Button {
            starttestfortcpconnections = true
        } label: {
            Label("TCP", systemImage: "play.fill")
        }
        .keyboardShortcut("t", modifiers: [.command])
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
        .keyboardShortcut("t", modifiers: [.command])
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
        .keyboardShortcut("i", modifiers: [.command])
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
        .keyboardShortcut("s", modifiers: [.command])
    }
}

struct FocusedEstimateBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedExecuteBinding: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedTCPconnections: FocusedValueKey {
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

extension FocusedValues {
    var startestimation: FocusedEstimateBinding.Value? {
        get { self[FocusedEstimateBinding.self] }
        set { self[FocusedEstimateBinding.self] = newValue }
    }

    var startexecution: FocusedExecuteBinding.Value? {
        get { self[FocusedExecuteBinding.self] }
        set { self[FocusedExecuteBinding.self] = newValue }
    }

    var starttestfortcpconnections: FocusedTCPconnections.Value? {
        get { self[FocusedTCPconnections.self] }
        set { self[FocusedTCPconnections.self] = newValue }
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
}
