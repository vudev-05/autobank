package vn.autobank.autobank_mobile

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification
        val extras = notification.extras
        
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val postTime = sbn.postTime
        val lowerPkg = packageName.lowercase()

        // Kiểm tra tất cả các ứng dụng ngân hàng, ngân hàng số, ví điện tử, doanh nghiệp và tin nhắn SMS
        val combinedContent = "$title $text $bigText".lowercase()
        val isFinancialText = combinedContent.contains("vnd") ||
                combinedContent.contains("đ") ||
                combinedContent.contains("số dư") ||
                combinedContent.contains("so du") ||
                combinedContent.contains("biến động") ||
                combinedContent.contains("nhận tiền") ||
                combinedContent.contains("chuyển tiền") ||
                combinedContent.contains("thanh toán")

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
        val isBankOrSms = isKnownPackage || (isFinancialText && (lowerPkg.contains("pay") || lowerPkg.contains("money") || lowerPkg.contains("finance")))

        if (isBankOrSms) {
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
