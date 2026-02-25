package com.emocare.intercom.next.system.firebase

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import com.emocare.intercom.next.MainActivity
import com.emocare.intercom.next.R
import com.emocare.intercom.next.system.telecom.EmoCareCallMetadata
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint

/**
 * EmoCare Firebase Cloud Messaging Service
 * 
 * LINEレベル品質実現のためのプッシュ通知処理:
 * - VoIP着信通知
 * - バックグラウンド通知処理
 * - 緊急通知優先表示
 * - 通話開始トリガー
 */
@AndroidEntryPoint
class EmoCareFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "EmoCareFirebaseMsg"
        private const val INCOMING_CALL_CHANNEL_ID = "incoming_calls"
        private const val GENERAL_CHANNEL_ID = "general_notifications"
        private const val EMERGENCY_CHANNEL_ID = "emergency_notifications"
        
        // Notification types
        private const val TYPE_INCOMING_CALL = "incoming_call"
        private const val TYPE_CALL_ENDED = "call_ended"
        private const val TYPE_EMERGENCY_ALERT = "emergency_alert"
        private const val TYPE_GENERAL_MESSAGE = "general_message"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        
        // TODO: サーバーにトークンを送信
        sendTokenToServer(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "FCM message received from: ${remoteMessage.from}")
        Log.d(TAG, "Message data: ${remoteMessage.data}")
        
        val messageType = remoteMessage.data["type"] ?: TYPE_GENERAL_MESSAGE
        
        when (messageType) {
            TYPE_INCOMING_CALL -> handleIncomingCall(remoteMessage)
            TYPE_CALL_ENDED -> handleCallEnded(remoteMessage)
            TYPE_EMERGENCY_ALERT -> handleEmergencyAlert(remoteMessage)
            TYPE_GENERAL_MESSAGE -> handleGeneralMessage(remoteMessage)
            else -> {
                Log.w(TAG, "Unknown message type: $messageType")
                handleGeneralMessage(remoteMessage)
            }
        }
    }

    private fun handleIncomingCall(remoteMessage: RemoteMessage) {
        Log.d(TAG, "Handling incoming call notification")
        
        val data = remoteMessage.data
        val callId = data["call_id"] ?: return
        val callerId = data["caller_id"] ?: return
        val callerName = data["caller_name"] ?: "Unknown"
        val channelId = data["channel_id"]
        val channelName = data["channel_name"]
        val isEmergency = data["is_emergency"]?.toBoolean() ?: false
        
        // 着信通話メタデータ作成
        val metadata = EmoCareCallMetadata.createIncoming(
            callId = callId,
            callerId = callerId,
            callerName = callerName,
            channelId = channelId,
            channelName = channelName,
            isEmergency = isEmergency
        )
        
        // 着信通知表示
        showIncomingCallNotification(metadata)
        
        // TODO: CallKitに着信を通知
        // TODO: アプリがフォアグラウンドの場合は直接着信UI表示
    }

    private fun handleCallEnded(remoteMessage: RemoteMessage) {
        Log.d(TAG, "Handling call ended notification")
        
        val callId = remoteMessage.data["call_id"] ?: return
        
        // 着信通知を削除
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(callId.hashCode())
        
        // TODO: 通話終了処理
    }

    private fun handleEmergencyAlert(remoteMessage: RemoteMessage) {
        Log.d(TAG, "Handling emergency alert")
        
        val title = remoteMessage.data["title"] ?: "緊急アラート"
        val body = remoteMessage.data["body"] ?: "緊急事態が発生しました"
        val alertId = remoteMessage.data["alert_id"] ?: System.currentTimeMillis().toString()
        
        showEmergencyNotification(title, body, alertId)
    }

    private fun handleGeneralMessage(remoteMessage: RemoteMessage) {
        Log.d(TAG, "Handling general message")
        
        val title = remoteMessage.notification?.title ?: remoteMessage.data["title"] ?: "EmoCare"
        val body = remoteMessage.notification?.body ?: remoteMessage.data["body"] ?: ""
        
        if (body.isNotEmpty()) {
            showGeneralNotification(title, body)
        }
    }

    private fun showIncomingCallNotification(metadata: EmoCareCallMetadata) {
        val title = if (metadata.isEmergency) "緊急着信" else "着信"
        val body = "${metadata.callerName}${
            if (metadata.channelName != null) " (${metadata.channelName})" else ""
        }"
        
        // 応答アクション
        val answerIntent = Intent(this, MainActivity::class.java).apply {
            action = "ACTION_ANSWER_CALL"
            putExtras(metadata.toBundle())
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val answerPendingIntent = PendingIntent.getActivity(
            this, 0, answerIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 拒否アクション
        val rejectIntent = Intent(this, MainActivity::class.java).apply {
            action = "ACTION_REJECT_CALL"
            putExtras(metadata.toBundle())
        }
        val rejectPendingIntent = PendingIntent.getActivity(
            this, 1, rejectIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, INCOMING_CALL_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(if (metadata.isEmergency) NotificationCompat.PRIORITY_MAX else NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(answerPendingIntent, true)
            .addAction(R.drawable.ic_call, "応答", answerPendingIntent)
            .addAction(R.drawable.ic_call_end, "拒否", rejectPendingIntent)
            .setStyle(NotificationCompat.CallStyle.forIncomingCall(
                android.app.Person.Builder()
                    .setName(metadata.callerName)
                    .setImportant(metadata.isEmergency)
                    .build(),
                rejectPendingIntent,
                answerPendingIntent
            ))
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(metadata.callId.hashCode(), notification)
    }

    private fun showEmergencyNotification(title: String, body: String, alertId: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, EMERGENCY_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(resources.getColor(android.R.color.holo_red_light, null))
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(alertId.hashCode(), notification)
    }

    private fun showGeneralNotification(title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, GENERAL_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannels() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // 着信通話チャンネル
        val incomingCallChannel = NotificationChannel(
            INCOMING_CALL_CHANNEL_ID,
            "着信",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "VoIP着信通知を表示します"
            enableVibration(true)
            setSound(null, null) // システムの着信音を使用
        }
        
        // 一般通知チャンネル
        val generalChannel = NotificationChannel(
            GENERAL_CHANNEL_ID,
            "一般通知",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "一般的な通知を表示します"
        }
        
        // 緊急通知チャンネル
        val emergencyChannel = NotificationChannel(
            EMERGENCY_CHANNEL_ID,
            "緊急通知",
            NotificationManager.IMPORTANCE_MAX
        ).apply {
            description = "緊急アラートを表示します"
            enableVibration(true)
            enableLights(true)
            lightColor = android.graphics.Color.RED
        }
        
        notificationManager.createNotificationChannels(
            listOf(incomingCallChannel, generalChannel, emergencyChannel)
        )
    }

    private fun sendTokenToServer(token: String) {
        // TODO: Supabaseにトークンを送信
        Log.d(TAG, "Sending token to server: $token")
    }
}