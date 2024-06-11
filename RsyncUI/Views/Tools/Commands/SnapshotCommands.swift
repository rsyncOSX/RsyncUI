//
//  SnapshotCommands.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 08/11/2022.
//
/*

 import Foundation
 import SwiftUI

 struct SnapshotCommands: Commands {
     @FocusedBinding(\.tagsnapshot) private var tagsnapshot

     var body: some Commands {
         CommandMenu("Snapshots") {
             Tagsnapshot(tagsnapshot: $tagsnapshot)
         }
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

 struct FocusedTagsnapshot: FocusedValueKey {
     typealias Value = Binding<Bool>
 }

 extension FocusedValues {
     var tagsnapshot: FocusedTagsnapshot.Value? {
         get { self[FocusedTagsnapshot.self] }
         set { self[FocusedTagsnapshot.self] = newValue }
     }
 }

 */
