//
//  SnapshotCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/11/2022.
//

import Foundation
import SwiftUI

struct SnapshotCommands: Commands {
    @FocusedBinding(\.selectsnapshot) private var selectsnapshot
    @FocusedBinding(\.tagsnapshot) private var tagsnapshot

    var body: some Commands {
        CommandMenu("Snapshots") {
            Selectsnapshot(selectsnapshot: $selectsnapshot)
            Tagsnapshot(tagsnapshot: $tagsnapshot)
        }
    }

    func select() {
        selectsnapshot = true
    }
}

struct Selectsnapshot: View {
    @Binding var selectsnapshot: Bool?

    var body: some View {
        Button {
            selectsnapshot = true
        } label: {
            Text("Select snapshot")
        }
        .keyboardShortcut("o", modifiers: [.command])
    }
}

struct Tagsnapshot: View {
    @Binding var tagsnapshot: Bool?

    var body: some View {
        Button {
            tagsnapshot = true
        } label: {
            Text("Tag snapshot")
        }
        .keyboardShortcut("t", modifiers: [.command])
    }
}

struct FocusedSelectsnapshot: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var selectsnapshot: FocusedSelectsnapshot.Value? {
        get { self[FocusedSelectsnapshot.self] }
        set { self[FocusedSelectsnapshot.self] = newValue }
    }
}

struct FocusedTagsnapshot: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var tagsnapshot: FocusedTagsnapshot.Value? {
        get { self[FocusedTagsnapshot.self] }
        set { self[FocusedTagsnapshot.self] = newValue }
    }
}
