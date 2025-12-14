package com.example.daily_ayah

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyAyahWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val TAG = "DailyAyahWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(
                    context.packageName,
                    R.layout.widget_layout
                ).apply {
                    // Get data from HomeWidget plugin
                    val widgetData = HomeWidgetPlugin.getData(context)
                    val imagePath = widgetData.getString("widget_image_path", null)
                    
                    Log.d(TAG, "Data Retrieved - Image Path: $imagePath")

                    if (imagePath != null) {
                        try {
                             val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                             if (bitmap != null) {
                                 setImageViewBitmap(R.id.widget_image_view, bitmap)
                             } else {
                                 Log.e(TAG, "Failed to decode bitmap from path: $imagePath")
                             }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error decoding bitmap", e)
                        }
                    } else {
                        Log.w(TAG, "No image path found")
                    }

                    // Set click intent to open app
                    val intent = Intent(context, MainActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                    
                    val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }

                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "Widget $widgetId updated successfully (IMAGE MODE)")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $widgetId", e)
            }
        }
    }
}
