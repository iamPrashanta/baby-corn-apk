package com.babycorn.app

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.babycorn.app.native.*

class MainActivity: FlutterFragmentActivity() {
    private var ringtoneBridge: RingtoneBridge? = null
    private var alarmBridge: AlarmBridge? = null
    private var notificationBridge: NotificationBridge? = null
    private var contactBridge: ContactBridge? = null
    private var callBridge: CallBridge? = null
    private var smsBridge: SmsBridge? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        ringtoneBridge = RingtoneBridge(this, messenger)
        alarmBridge = AlarmBridge(this, messenger)
        notificationBridge = NotificationBridge(this, messenger)
        contactBridge = ContactBridge(this, messenger)
        callBridge = CallBridge(this, messenger)
        smsBridge = SmsBridge(this, messenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        ringtoneBridge?.let {
            if (it.onActivityResult(requestCode, resultCode, data)) {
                return
            }
        }
    }
}
