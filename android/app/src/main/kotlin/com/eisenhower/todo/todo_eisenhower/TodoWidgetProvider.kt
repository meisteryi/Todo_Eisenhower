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
                val q2Count = widgetData.getInt("q2_count", 0)
                val q3Count = widgetData.getInt("q3_count", 0)
                val q4Count = widgetData.getInt("q4_count", 0)
                val totalPending = widgetData.getInt("total_pending", 0)
                val urgentText = widgetData.getString("urgent_task_text", "없음") ?: "없음"
                val weeklyText = widgetData.getString("weekly_stats_text", "🏆 오운완 100%") ?: "🏆 오운완 100%"

                setTextViewText(R.id.widget_title, "아이젠하워 & 오운완")
                setTextViewText(R.id.widget_streak, "🔥 ${streak}일째")

                setTextViewText(R.id.widget_q1, "🚨 Q1 긴급: ${q1Count}개")
                setTextViewText(R.id.widget_q2, "🎯 Q2 목표: ${q2Count}개")
                setTextViewText(R.id.widget_q3, "👥 Q3 대리: ${q3Count}개")
                setTextViewText(R.id.widget_q4, "🗑 Q4 휴식: ${q4Count}개")

                setTextViewText(R.id.widget_urgent_task, "⏰ 최우선: ${urgentText}")
                setTextViewText(R.id.widget_weekly_stats, weeklyText)
                setTextViewText(R.id.widget_total_status, "전체: ${totalPending}개")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
