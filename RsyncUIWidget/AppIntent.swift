//
//  AppIntent.swift
//  RsyncUIWidget
//
//  Created by Thomas Evensen on 12/01/2025.
//

import WidgetKit
import AppIntents

struct WidgetsConfig: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title = LocalizedStringResource(stringLiteral: "Select Config")
  nonisolated(unsafe) static var description = IntentDescription("View all some emojis")
 
  @Parameter(title: "Emoji")
  var showEmoji: Bool?
  
  init(showEmoji: Bool) {
    self.showEmoji = showEmoji
  }
  
  init() {
    self.showEmoji = true
  }
}
