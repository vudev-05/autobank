package com.docthongbaobank.app

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class NotificationListener : NotificationListenerService() {
    companion object {
        // Lưu cache các thông báo gần nhất trong 5 giây để triệt tiêu việc Android gọi onNotificationPosted 2 lần cho cùng 1 thông báo
        private val recentNotificationMap = java.util.concurrent.ConcurrentHashMap<String, Long>()
        private const val DEDUP_WINDOW_MS = 4000L // 4 giây
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        // Bỏ qua tất cả thông báo do chính ứng dụng AutoBank tự phát ra (tránh vòng lặp tự bắt thông báo)
        if (packageName == this.packageName || packageName == "com.docthongbaobank.app" || packageName == "vn.autobank.autobank_mobile") {
            return
        }
        val notification = sbn.notification
        val extras = notification.extras
        
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val postTime = sbn.postTime
        val lowerPkg = packageName.lowercase()

        // 1. Kiểm tra tất cả các ứng dụng ngân hàng, ngân hàng số, ví điện tử, doanh nghiệp và tin nhắn SMS
        val combinedContent = "$title $text $bigText".lowercase()
        val isFinancialText = combinedContent.contains("vnd") ||
                combinedContent.contains("đ") ||
                combinedContent.contains("số dư") ||
                combinedContent.contains("so du") ||
                combinedContent.contains("biến động") ||
                combinedContent.contains("bien dong") ||
                combinedContent.contains("nhận tiền") ||
                combinedContent.contains("nhan tien") ||
                combinedContent.contains("chuyển tiền") ||
                combinedContent.contains("chuyen tien") ||
                combinedContent.contains("thanh toán") ||
                combinedContent.contains("thanh toan") ||
                combinedContent.contains("thành công") ||
                combinedContent.contains("thanh cong") ||
                combinedContent.contains("tài khoản") ||
                combinedContent.contains("tai khoan") ||
                combinedContent.contains("giao dịch") ||
                combinedContent.contains("giao dich") ||
                combinedContent.contains("gd:") ||
                combinedContent.contains("+")

        val knownPackages = listOf(
            // Ngân hàng thương mại & Neobanks
            "vcb", "vietcombank", "techcombank", "mbmobile", "bidv", "vietinbank", "acb",
            "vpb", "vpbank", "sacombank", "hdbank", "agribank", "tpbank", "scb", "pvcombank",
            "bacabank", "ocb", "shb", "seabank", "namabank", "lpbank", "lienviet", "vib",
            "eximbank", "msb", "uob", "cimb", "hongleong", "publicbank", "scb", "hsbc",
            "wooribank", "ibk", "kasikorn", "kienlongbank", "saigonbank", "vietabank",
            "ncb", "pgbank", "oceanbank", "coopbank", "bidc", "baovietbank", "abbank",
            "indovinabank", "gpbank", "vietbank", "shinhan",
            // Neobank
            "cake", "liobank", "tnex", "timo", "vikki", "mbv",
            // Ví điện tử
            "momo", "zalopay", "airpay", "shopeepay", "viettelmoney", "viettelpay", "vnptmoney",
            // Doanh nghiệp
            "digibiz", "ibank", "biz", "corporate",
            // SMS & Tin nhắn hệ thống
            "messaging", "mms", "sms"
        )

        val isKnownPackage = knownPackages.any { lowerPkg.contains(it) } || lowerPkg.contains("bank")
        val isBankOrFinancial = isKnownPackage || isFinancialText

        if (isBankOrFinancial) {
            val now = System.currentTimeMillis()

            // 2. Triệt tiêu trùng lặp: Tạo key định danh thông báo dựa trên sbn.key và nội dung giao dịch
            val cleanBody = if (bigText.trim().length > text.trim().length) bigText.trim() else text.trim()
            val dedupKey = "${sbn.key}_${packageName}_${title}_${cleanBody.take(60)}"

            val lastSeen = recentNotificationMap[dedupKey]
            if (lastSeen != null && (now - lastSeen) < DEDUP_WINDOW_MS) {
                Log.d("AutoBank", "Bỏ qua thông báo trùng lặp từ Android NotificationListener: $packageName")
                return
            }
            recentNotificationMap[dedupKey] = now

            // Dọn dẹp cache cũ > 30 giây để tránh tốn bộ nhớ
            if (recentNotificationMap.size > 50) {
                val it = recentNotificationMap.entries.iterator()
                while (it.hasNext()) {
                    val entry = it.next()
                    if (now - entry.value > 30000L) {
                        it.remove()
                    }
                }
            }

            Log.d("AutoBank", "Notification received from $packageName: $title - $text")
            
            // Broadcast the notification to the Flutter MainActivity
            val intent = Intent("vn.autobank.NOTIFICATION").apply {
                putExtra("title", title)
                putExtra("text", text)
                putExtra("bigText", bigText)
                putExtra("package", packageName)
                putExtra("postTime", postTime)
            }
            LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Not used
    }
}
