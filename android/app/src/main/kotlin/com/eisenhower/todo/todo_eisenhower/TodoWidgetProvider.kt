package com.eisenhower.todo.todo_eisenhower

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val streak = widgetData.getInt("workout_streak", 0)
                val q1Count = widgetData.getInt("q1_count", 0)
                val totalPending = widgetData.getInt("total_pending", 0)
                val completedWorkouts = widgetData.getInt("workout_completed", 0)
                val totalWorkouts = widgetData.getInt("workout_total", 0)

                setTextViewText(R.id.widget_title, "아이젠하워 & 오운완")
                setTextViewText(R.id.widget_streak, "🔥 연속 ${streak}일째 오운완!")
                setTextViewText(
                    R.id.widget_todo_status,
                    "Q1 긴급: ${q1Count}개 (전체 ${totalPending}개) | 운동: ${completedWorkouts}/${totalWorkouts}"
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
