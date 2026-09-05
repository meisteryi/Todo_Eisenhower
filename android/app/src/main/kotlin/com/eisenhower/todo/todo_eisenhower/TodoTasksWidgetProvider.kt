package com.eisenhower.todo.todo_eisenhower

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodoTasksWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_tasks_layout).apply {
                val q1Count = widgetData.getInt("q1_count", 0)
                val q2Count = widgetData.getInt("q2_count", 0)

                val q1T1 = widgetData.getString("q1_title_1", "") ?: ""
                val q1T2 = widgetData.getString("q1_title_2", "") ?: ""
                val q1T3 = widgetData.getString("q1_title_3", "") ?: ""

                val q2T1 = widgetData.getString("q2_title_1", "") ?: ""
                val q2T2 = widgetData.getString("q2_title_2", "") ?: ""
                val q2T3 = widgetData.getString("q2_title_3", "") ?: ""

                setTextViewText(R.id.widget_q1_header, "🚨 Q1 긴급 (${q1Count})")
                setTextViewText(R.id.widget_q2_header, "🎯 Q2 목표 (${q2Count})")

                setTextViewText(R.id.widget_q1_item1, if (q1T1.isNotEmpty()) "• $q1T1" else "• (없음)")
                setTextViewText(R.id.widget_q1_item2, if (q1T2.isNotEmpty()) "• $q1T2" else "")
                setTextViewText(R.id.widget_q1_item3, if (q1T3.isNotEmpty()) "• $q1T3" else "")

                setTextViewText(R.id.widget_q2_item1, if (q2T1.isNotEmpty()) "• $q2T1" else "• (없음)")
                setTextViewText(R.id.widget_q2_item2, if (q2T2.isNotEmpty()) "• $q2T2" else "")
                setTextViewText(R.id.widget_q2_item3, if (q2T3.isNotEmpty()) "• $q2T3" else "")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
