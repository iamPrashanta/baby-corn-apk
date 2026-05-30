package com.babycorn.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BabyCornWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val sleepStr = widgetData.getString("sleep_today", "0m")
                val lastFeedStr = widgetData.getString("last_feed", "No feeds yet")
                
                setTextViewText(R.id.sleep_text, "Sleep: $sleepStr")
                setTextViewText(R.id.feed_text, "Feed: $lastFeedStr")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
