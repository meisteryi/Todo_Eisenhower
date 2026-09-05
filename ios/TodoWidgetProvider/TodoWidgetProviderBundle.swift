//
//  TodoWidgetProviderBundle.swift
//  TodoWidgetProvider
//
//  Created by 이주형 on 9/5/26.
//

import WidgetKit
import SwiftUI

@main
struct TodoWidgetProviderBundle: WidgetBundle {
    var body: some Widget {
        TodoWidgetProvider()
        TodoTasksWidgetProvider()
    }
}
