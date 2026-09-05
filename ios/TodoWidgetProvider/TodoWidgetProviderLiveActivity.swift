//
//  TodoWidgetProviderLiveActivity.swift
//  TodoWidgetProvider
//
//  Created by 이주형 on 9/5/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TodoWidgetProviderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TodoWidgetProviderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodoWidgetProviderAttributes.self) { context in
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

extension TodoWidgetProviderAttributes {
    fileprivate static var preview: TodoWidgetProviderAttributes {
        TodoWidgetProviderAttributes(name: "World")
    }
}

extension TodoWidgetProviderAttributes.ContentState {
    fileprivate static var smiley: TodoWidgetProviderAttributes.ContentState {
        TodoWidgetProviderAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TodoWidgetProviderAttributes.ContentState {
         TodoWidgetProviderAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TodoWidgetProviderAttributes.preview) {
   TodoWidgetProviderLiveActivity()
} contentStates: {
    TodoWidgetProviderAttributes.ContentState.smiley
    TodoWidgetProviderAttributes.ContentState.starEyes
}
