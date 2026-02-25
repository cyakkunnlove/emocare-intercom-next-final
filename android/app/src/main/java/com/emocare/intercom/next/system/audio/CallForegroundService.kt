package com.emocare.intercom.next.system.audio

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.emocare.intercom.next.R
import dagger.hilt.android.AndroidEntryPoint

/**
 * 通話中フォアグラウンドサービス
 * 
 * LINEレベル品質実現のためのバックグラウンド通話継続:
 * - 通話中の永続的通知表示
 * - バックグラウンド実行保証
 * - システム強制終了防止
 * - 音声品質維持
 */
@AndroidEntryPoint
class CallForegroundService : Service() {

    companion object {
        private const val TAG = "CallForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "call_foreground_channel"
        
        const val ACTION_START_CALL = "START_CALL"
        const val ACTION_END_CALL = "END_CALL"
        const val ACTION_MUTE_CALL = "MUTE_CALL"
        const val ACTION_UNMUTE_CALL = "UNMUTE_CALL"
        
        const val EXTRA_CALL_ID = "call_id"
        const val EXTRA_CALLER_NAME = "caller_name"
        const val EXTRA_IS_INCOMING = "is_incoming"

        fun startCallService(
            context: Context,
            callId: String,
            callerName: String,
            isIncoming: Boolean
        ) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_START_CALL
                putExtra(EXTRA_CALL_ID, callId)
                putExtra(EXTRA_CALLER_NAME, callerName)
                putExtra(EXTRA_IS_INCOMING, isIncoming)
            }
            context.startForegroundService(intent)
        }

        fun stopCallService(context: Context, callId: String) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_END_CALL
                putExtra(EXTRA_CALL_ID, callId)
            }
            context.startService(intent)
        }
    }

    private var currentCallId: String? = null
    private var isCallActive = false
    private var isMuted = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Call foreground service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_CALL -> {
                val callId = intent.getStringExtra(EXTRA_CALL_ID) ?: return START_NOT_STICKY
                val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Unknown"
                val isIncoming = intent.getBooleanExtra(EXTRA_IS_INCOMING, false)
                
                startCall(callId, callerName, isIncoming)
            }
            
            ACTION_END_CALL -> {
                val callId = intent.getStringExtra(EXTRA_CALL_ID)
                endCall(callId)
            }
            
            ACTION_MUTE_CALL -> {
                toggleMute(true)
            }
            
            ACTION_UNMUTE_CALL -> {
                toggleMute(false)
            }
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Call foreground service destroyed")
    }

    private fun startCall(callId: String, callerName: String, isIncoming: Boolean) {
        Log.d(TAG, "Starting call: $callId, caller: $callerName, incoming: $isIncoming")
        
        currentCallId = callId
        isCallActive = true
        
        val notification = createCallNotification(callerName, isIncoming)
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun endCall(callId: String?) {
        Log.d(TAG, "Ending call: $callId")
        
        if (callId == null || callId == currentCallId) {
            currentCallId = null
            isCallActive = false
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun toggleMute(mute: Boolean) {
        isMuted = mute
        Log.d(TAG, "Toggle mute: $mute")
        
        // 通知を更新
        if (isCallActive && currentCallId != null) {
            val notification = createCallNotification(
                getCurrentCallerName(), 
                false // 通話中なので着信ではない
            )
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "通話中",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "通話中の状態を表示します"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun createCallNotification(callerName: String, isIncoming: Boolean): Notification {
        val title = if (isIncoming) "着信中" else "通話中"
        val text = "$callerName${if (isMuted) " (ミュート)" else ""}"

        // 通話終了アクション
        val endCallIntent = Intent(this, CallForegroundService::class.java).apply {
            action = ACTION_END_CALL
            putExtra(EXTRA_CALL_ID, currentCallId)
        }
        val endCallPendingIntent = PendingIntent.getService(
            this, 0, endCallIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ミュート切り替えアクション
        val muteAction = if (isMuted) ACTION_UNMUTE_CALL else ACTION_MUTE_CALL
        val muteIntent = Intent(this, CallForegroundService::class.java).apply {
            action = muteAction
        }
        val mutePendingIntent = PendingIntent.getService(
            this, 1, muteIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                if (isMuted) R.drawable.ic_mic_off else R.drawable.ic_mic,
                if (isMuted) "ミュート解除" else "ミュート",
                mutePendingIntent
            )
            .addAction(
                R.drawable.ic_call_end,
                "終話",
                endCallPendingIntent
            )
            .setStyle(NotificationCompat.CallStyle.forOngoingCall(
                android.app.Person.Builder()
                    .setName(callerName)
                    .setImportant(true)
                    .build(),
                endCallPendingIntent
            ))
            .build()
    }

    private fun getCurrentCallerName(): String {
        // TODO: 実際の通話相手名を取得
        return "通話中"
    }
}