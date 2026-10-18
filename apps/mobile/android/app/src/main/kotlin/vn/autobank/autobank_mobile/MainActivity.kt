package vn.autobank.autobank_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val EVENT_CHANNEL = "vn.autobank.mobile/notifications"
    private val METHOD_CHANNEL = "vn.autobank.mobile/permissions"
    
    private var eventSink: EventChannel.EventSink? = null

    private val notificationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "vn.autobank.NOTIFICATION") {
                val title = intent.getStringExtra("title") ?: ""
                val text = intent.getStringExtra("text") ?: ""
                val bigText = intent.getStringExtra("bigText") ?: ""
                val packageName = intent.getStringExtra("package") ?: ""
                val postTime = intent.getLongExtra("postTime", System.currentTimeMillis())
                
                val notificationData = mapOf(
                    "title" to title,
                    "text" to text,
                    "bigText" to bigText,
                    "package" to packageName,
                    "postTime" to postTime
                )
                
                runOnUiThread {
                    try {
                        eventSink?.success(notificationData)
                    } catch (t: Throwable) {
                        android.util.Log.e("AutoBank", "Error dispatching to Flutter eventSink", t)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup MethodChannel for checking/requesting permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    try {
                        val pkg = packageName
                        val listeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                        val secureEnabled = listeners != null && listeners.contains(pkg)
                        val compatEnabled = try {
                            androidx.core.app.NotificationManagerCompat.getEnabledListenerPackages(this).contains(pkg)
                        } catch (t: Throwable) {
                            false
                        }
                        result.success(secureEnabled || compatEnabled)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS").apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                        val ignored = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                        } else {
                            true
                        }
                        result.success(ignored)
                    } catch (t: Throwable) {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.parse("package:$packageName")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.success(false)
                    }
                }
                "ensureMaxVolume" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? android.media.AudioManager
                        if (audioManager != null) {
                            val maxVol = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                            // Kích âm lượng Media lên mức tối đa (100%) của điện thoại để đọc to rõ nhất
                            audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxVol, 0)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setScreenBrightness" -> {
                    try {
                        val brightness = (call.argument<Double>("brightness") ?: -1.0).toFloat()
                        val layoutParams = window.attributes
                        layoutParams.screenBrightness = brightness
                        window.attributes = layoutParams
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "showSystemNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Đọc Thông Báo Nhận Tiền"
                        val content = call.argument<String>("content") ?: ""
                        val channelType = call.argument<String>("type") ?: "system"
                        val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                        val isOngoing = call.argument<Boolean>("isOngoing") ?: false

                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
                        if (notificationManager != null) {
                            val channelId = "autobank_$channelType"
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                                val channelName = when (channelType) {
                                    "background" -> "Hoạt động nền 24/7"
                                    "promo" -> "Ưu đãi & Khuyến mãi"
                                    "auth" -> "Xác thực & Bảo mật"
                                    "transaction" -> "Biến động số dư"
                                    else -> "Thông báo hệ thống"
                                }
                                val importance = if (channelType == "background") {
                                    android.app.NotificationManager.IMPORTANCE_LOW
                                } else {
                                    android.app.NotificationManager.IMPORTANCE_HIGH
                                }
                                val channel = android.app.NotificationChannel(channelId, channelName, importance).apply {
                                    description = "Thông báo từ ứng dụng Đọc Thông Báo Nhận Tiền"
                                }
                                notificationManager.createNotificationChannel(channel)
                            }

                            val smallIconRes = try {
                                val resId = resources.getIdentifier("ic_notification", "drawable", packageName)
                                if (resId != 0) resId else android.R.drawable.stat_notify_chat
                            } catch (e: Exception) {
                                android.R.drawable.stat_notify_chat
                            }

                            val builder = androidx.core.app.NotificationCompat.Builder(this, channelId)
                                .setSmallIcon(smallIconRes)
                                .setContentTitle(title)
                                .setContentText(content)
                                .setStyle(androidx.core.app.NotificationCompat.BigTextStyle().bigText(content))
                                .setPriority(
                                    if (channelType == "background") androidx.core.app.NotificationCompat.PRIORITY_LOW
                                    else androidx.core.app.NotificationCompat.PRIORITY_MAX
                                )
                                .setOngoing(isOngoing)
                                .setAutoCancel(!isOngoing)

                            val pendingIntent = android.app.PendingIntent.getActivity(
                                this,
                                0,
                                Intent(this, MainActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP },
                                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
                                } else {
                                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                                }
                            )
                            builder.setContentIntent(pendingIntent)

                            notificationManager.notify(id, builder.build())
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "cancelNotification" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
                        notificationManager?.cancel(id)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Setup EventChannel for streaming notifications to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    try {
                        eventSink = events
                        LocalBroadcastManager.getInstance(this@MainActivity)
                            .registerReceiver(notificationReceiver, IntentFilter("vn.autobank.NOTIFICATION"))
                    } catch (t: Throwable) {
                        android.util.Log.e("AutoBank", "Error registering receiver", t)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    try {
                        eventSink = null
                        LocalBroadcastManager.getInstance(this@MainActivity)
                            .unregisterReceiver(notificationReceiver)
                    } catch (t: Throwable) {
                        android.util.Log.e("AutoBank", "Error unregistering receiver", t)
                    }
                }
            }
        )
    }

    override fun cleanUpFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        try {
            eventSink = null
            LocalBroadcastManager.getInstance(this).unregisterReceiver(notificationReceiver)
        } catch (t: Throwable) {}
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        try {
            eventSink = null
            LocalBroadcastManager.getInstance(this).unregisterReceiver(notificationReceiver)
        } catch (t: Throwable) {}
        super.onDestroy()
    }
}
