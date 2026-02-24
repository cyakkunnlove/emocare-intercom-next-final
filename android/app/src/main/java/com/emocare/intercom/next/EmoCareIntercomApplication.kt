package com.emocare.intercom.next

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.content.getSystemService
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class EmoCareIntercomApplication : Application() {

    companion object {
        private const val TAG = "EmoCareIntercom"
        
        // 通知チャンネルID
        const val CHANNEL_ID_VOIP_CALLS = "voip_calls"
        const val CHANNEL_ID_PTT = "ptt_notifications"
        const val CHANNEL_ID_GENERAL = "general_notifications"
        
        lateinit var instance: EmoCareIntercomApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        
        Log.d(TAG, "✅ EmoCare Intercom Next Application starting...")
        
        // 通知チャンネル作成
        createNotificationChannels()
        
        // PhoneAccount登録
        registerPhoneAccount()
        
        // アプリ初期化
        initializeApp()
        
        Log.d(TAG, "✅ Application initialization completed")
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService<NotificationManager>()
                ?: return

            // VoIP通話チャンネル
            val voipChannel = NotificationChannel(
                CHANNEL_ID_VOIP_CALLS,
                "VoIP通話",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "着信通話とVoIP関連の通知"
                enableVibration = true
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            // PTTチャンネル
            val pttChannel = NotificationChannel(
                CHANNEL_ID_PTT,
                "PTT通信",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Push-to-Talk通信の通知"
                enableVibration = false
                setShowBadge(false)
            }

            // 一般通知チャンネル
            val generalChannel = NotificationChannel(
                CHANNEL_ID_GENERAL,
                "一般通知",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "アプリの一般的な通知"
                enableVibration = true
                setShowBadge(true)
            }

            // チャンネル登録
            notificationManager.createNotificationChannels(
                listOf(voipChannel, pttChannel, generalChannel)
            )

            Log.d(TAG, "✅ Notification channels created")
        }
    }

    private fun registerPhoneAccount() {
        try {
            com.emocare.intercom.next.system.telecom.PhoneAccountManager
                .registerPhoneAccount(this)
            Log.d(TAG, "✅ PhoneAccount registered")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register PhoneAccount", e)
        }
    }

    private fun initializeApp() {
        // アプリケーション固有の初期化処理
        try {
            // セキュリティ初期化
            initializeSecurity()
            
            // ネットワーク設定
            initializeNetwork()
            
            Log.d(TAG, "✅ App components initialized")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to initialize app components", e)
        }
    }

    private fun initializeSecurity() {
        // TODO: セキュリティ関連の初期化
        // - キーストア設定
        // - 証明書ピニング
        // - セキュアストレージ初期化
    }

    private fun initializeNetwork() {
        // TODO: ネットワーク設定
        // - OkHttp設定
        // - Supabase初期化
        // - LiveKit設定
    }

    // アプリケーション全体で使用できるコンテキスト
    fun getApplicationContext(): Context = applicationContext

    // デバッグ情報の出力
    fun getAppInfo(): String {
        return """
            App: EmoCare Intercom Next
            Version: ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})
            Debug: ${BuildConfig.DEBUG}
            Package: ${BuildConfig.APPLICATION_ID}
        """.trimIndent()
    }
}