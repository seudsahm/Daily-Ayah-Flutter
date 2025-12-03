package com.example.daily_ayah

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyAyahWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(
                context.packageName,
                R.layout.widget_layout
            ).apply {
                // Get data from HomeWidget plugin
                val widgetData = HomeWidgetPlugin.getData(context)
                val streakCount = widgetData.getString("streak_count", "0")
                val streakLabel = widgetData.getString("streak_label", "Day Streak")

                // Update widget views
                setTextViewText(R.id.widget_streak_count, streakCount)
                setTextViewText(R.id.widget_streak_label, streakLabel)

                // Set click intent to open app
                val intent = Intent(context, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                setOnClickPendingIntent(R.id.widget_streak_count, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
