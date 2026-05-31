package com.babycorn.app.native

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AlarmBridge(private val activity: Activity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.babycorn.app/alarm")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "setAlarm") {
            // Implementation for setting an alarm
            result.success(null)
        } else if (call.method == "cancelAlarm") {
            // Implementation for cancelling an alarm
            result.success(null)
        } else {
            result.notImplemented()
        }
    }
}
