//
//  Runshaw_Bus_WidgetLiveActivity.swift
//  Runshaw Bus Widget
//
//  Created by Jacob on 24/04/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Runshaw_Bus_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Runshaw_Bus_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Runshaw_Bus_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Runshaw_Bus_WidgetAttributes {
    fileprivate static var preview: Runshaw_Bus_WidgetAttributes {
        Runshaw_Bus_WidgetAttributes(name: "World")
    }
}

extension Runshaw_Bus_WidgetAttributes.ContentState {
    fileprivate static var smiley: Runshaw_Bus_WidgetAttributes.ContentState {
        Runshaw_Bus_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Runshaw_Bus_WidgetAttributes.ContentState {
         Runshaw_Bus_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Runshaw_Bus_WidgetAttributes.preview) {
   Runshaw_Bus_WidgetLiveActivity()
} contentStates: {
    Runshaw_Bus_WidgetAttributes.ContentState.smiley
    Runshaw_Bus_WidgetAttributes.ContentState.starEyes
}
