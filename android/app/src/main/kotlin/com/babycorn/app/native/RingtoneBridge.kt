package com.babycorn.app.native

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RingtoneBridge(private val activity: Activity, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.babycorn.app/ringtone_picker")
    private var pendingResult: MethodChannel.Result? = null
    val requestCode = 999

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "pickRingtone") {
            pendingResult = result
            
            val currentUriString = call.argument<String>("currentUri")
            val isAlarm = call.argument<Boolean>("isAlarm") ?: true
            
            val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, if (isAlarm) RingtoneManager.TYPE_ALARM else RingtoneManager.TYPE_NOTIFICATION)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
            
            if (currentUriString != null && currentUriString.startsWith("content://")) {
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUriString))
            } else {
                val defaultUri = RingtoneManager.getDefaultUri(if (isAlarm) RingtoneManager.TYPE_ALARM else RingtoneManager.TYPE_NOTIFICATION)
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, defaultUri)
            }

            activity.startActivityForResult(intent, requestCode)
        } else {
            result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == this.requestCode) {
            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri? = data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                if (uri != null) {
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.success("silent")
                }
            } else {
                pendingResult?.success(null) // Cancelled
            }
            pendingResult = null
            return true
        }
        return false
    }
}
