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
    // @FocusedBinding(\.starttestfortcpconnections) private var starttestfortcpconnections
    @FocusedBinding(\.selecttask) private var selectttask

    var body: some Commands {
        CommandMenu("Execute") {
            StarteestimateButton(startestimation: $startestimation)
            StartexecuteButton(startexecution: $startexecution)
            SelectTask(selecttask: $selectttask)
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
            Label("Select", systemImage: "play.fill")
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
}
