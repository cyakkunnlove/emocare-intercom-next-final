package com.emocare.intercom.next

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import com.emocare.intercom.next.features.auth.AuthenticationViewModel
import com.emocare.intercom.next.features.voip.CallViewModel
import com.emocare.intercom.next.ui.components.EmoCareIntercomApp
import com.emocare.intercom.next.ui.theme.EmoCareIntercomTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        
        // インテント処理用の定数
        const val EXTRA_CHANNEL_ID = "channel_id"
        const val EXTRA_CALL_ID = "call_id"
        const val EXTRA_IS_EMERGENCY = "is_emergency"
        const val EXTRA_AUTO_ANSWER = "auto_answer"
    }

    // ViewModels
    private val authViewModel: AuthenticationViewModel by viewModels()
    private val callViewModel: CallViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        // スプラッシュスクリーン設定
        val splashScreen = installSplashScreen()
        
        // Edge-to-Edge表示
        enableEdgeToEdge()
        
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "✅ MainActivity created")
        
        // スプラッシュスクリーンの表示条件
        splashScreen.setKeepOnScreenCondition {
            !authViewModel.isInitialized.value
        }
        
        // UI設定
        setContent {
            EmoCareIntercomTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    EmoCareIntercomApp(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(innerPadding),
                        authViewModel = authViewModel,
                        callViewModel = callViewModel
                    )
                }
            }
        }

        // インテント処理（着信など）
        handleIntent(intent)
        
        // 初期化処理
        initializeActivity()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, "🔄 New intent received")
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "▶️ Activity resumed")
        
        // フォアグラウンドに来た時の処理
        lifecycleScope.launch {
            callViewModel.onActivityResumed()
        }
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "⏸️ Activity paused")
        
        // バックグラウンドに移る時の処理
        lifecycleScope.launch {
            callViewModel.onActivityPaused()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "🗑️ Activity destroyed")
    }

    private fun initializeActivity() {
        lifecycleScope.launch {
            // 短い遅延を入れて、Composeの初期化を待つ
            delay(100)
            
            try {
                // 認証状態をチェック
                authViewModel.checkAuthenticationStatus()
                
                // 権限チェック
                checkAndRequestPermissions()
                
                Log.d(TAG, "✅ Activity initialization completed")
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to initialize activity", e)
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        intent ?: return
        
        Log.d(TAG, "📨 Handling intent: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_VIEW -> {
                handleDeepLink(intent)
            }
            "android.intent.action.CALL" -> {
                handleIncomingCall(intent)
            }
            else -> {
                handleCustomIntent(intent)
            }
        }
        
        // インテント処理後にクリア
        intent.removeExtra(EXTRA_CHANNEL_ID)
        intent.removeExtra(EXTRA_CALL_ID)
        intent.removeExtra(EXTRA_IS_EMERGENCY)
        intent.removeExtra(EXTRA_AUTO_ANSWER)
    }

    private fun handleDeepLink(intent: Intent) {
        val data = intent.data ?: return
        
        Log.d(TAG, "🔗 Handling deep link: $data")
        
        when (data.host) {
            "call" -> {
                val channelId = data.getQueryParameter("channel_id")
                val callId = data.getQueryParameter("call_id")
                
                if (!channelId.isNullOrBlank() && !callId.isNullOrBlank()) {
                    lifecycleScope.launch {
                        callViewModel.handleIncomingCall(
                            channelId = channelId,
                            callId = callId
                        )
                    }
                }
            }
        }
    }

    private fun handleIncomingCall(intent: Intent) {
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID)
        val callId = intent.getStringExtra(EXTRA_CALL_ID)
        val isEmergency = intent.getBooleanExtra(EXTRA_IS_EMERGENCY, false)
        val autoAnswer = intent.getBooleanExtra(EXTRA_AUTO_ANSWER, false)
        
        Log.d(TAG, "📞 Handling incoming call: channelId=$channelId, callId=$callId, emergency=$isEmergency")
        
        if (!channelId.isNullOrBlank() && !callId.isNullOrBlank()) {
            lifecycleScope.launch {
                if (autoAnswer) {
                    callViewModel.answerCall(channelId, callId)
                } else {
                    callViewModel.handleIncomingCall(channelId, callId)
                }
            }
        }
    }

    private fun handleCustomIntent(intent: Intent) {
        // カスタムインテントの処理
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID)
        
        if (!channelId.isNullOrBlank()) {
            Log.d(TAG, "🎯 Navigating to channel: $channelId")
            lifecycleScope.launch {
                // チャンネル画面への遷移処理
                // TODO: Navigation処理を実装
            }
        }
    }

    private fun checkAndRequestPermissions() {
        // 必要な権限をチェック
        // TODO: 権限チェック・リクエスト処理を実装
        
        val requiredPermissions = arrayOf(
            android.Manifest.permission.RECORD_AUDIO,
            android.Manifest.permission.MODIFY_AUDIO_SETTINGS,
            android.Manifest.permission.MANAGE_OWN_CALLS
        )
        
        Log.d(TAG, "🔐 Checking permissions: ${requiredPermissions.joinToString()}")
    }

    // アクティビティの状態情報
    fun getActivityInfo(): String {
        return """
            Activity: MainActivity
            Created: ${lifecycle.currentState}
            Intent: ${intent?.action ?: "none"}
            Package: ${packageName}
        """.trimIndent()
    }
}