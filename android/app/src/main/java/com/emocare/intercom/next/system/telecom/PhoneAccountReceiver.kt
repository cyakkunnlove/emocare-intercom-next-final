package com.emocare.intercom.next.system.telecom

import android.content.*
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log
import com.emocare.intercom.next.R

/**
 * PhoneAccount登録用BroadcastReceiver
 * 
 * Android Telecom Framework統合のためのPhoneAccount管理:
 * - システム起動時の自動登録
 * - アプリ更新時の再登録
 * - VoIP通話機能の有効化
 */
class PhoneAccountReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PhoneAccountReceiver"
        const val PHONE_ACCOUNT_ID = "emocare_intercom_next"
        const val PHONE_ACCOUNT_LABEL = "EmoCare Intercom"
        
        /**
         * PhoneAccountを手動で登録
         */
        fun registerPhoneAccount(context: Context) {
            val receiver = PhoneAccountReceiver()
            receiver.registerPhoneAccountInternal(context)
        }
        
        /**
         * 登録済みPhoneAccountHandleを取得
         */
        fun getPhoneAccountHandle(context: Context): PhoneAccountHandle {
            val componentName = ComponentName(context, EmoCareConnectionService::class.java)
            return PhoneAccountHandle(componentName, PHONE_ACCOUNT_ID)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "Device boot completed - registering phone account")
                registerPhoneAccountInternal(context)
            }
            
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "App package replaced - re-registering phone account")
                registerPhoneAccountInternal(context)
            }
        }
    }

    private fun registerPhoneAccountInternal(context: Context) {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (telecomManager == null) {
                Log.e(TAG, "TelecomManager not available")
                return
            }

            // PhoneAccountHandle作成
            val phoneAccountHandle = getPhoneAccountHandle(context)
            
            // PhoneAccount作成
            val phoneAccount = PhoneAccount.builder(phoneAccountHandle, PHONE_ACCOUNT_LABEL)
                .setCapabilities(
                    PhoneAccount.CAPABILITY_SELF_MANAGED or
                    PhoneAccount.CAPABILITY_SUPPORTS_VIDEO_CALLING or
                    PhoneAccount.CAPABILITY_CALL_PROVIDER
                )
                .setIcon(context.resources.getDrawable(R.drawable.ic_notification, null).loadDrawable())
                .setShortDescription("EmoCare VoIPインターコム通話")
                .addSupportedUriScheme(PhoneAccount.SCHEME_TEL)
                .addSupportedUriScheme(PhoneAccount.SCHEME_SIP)
                .build()

            // PhoneAccountを登録
            telecomManager.registerPhoneAccount(phoneAccount)
            
            Log.i(TAG, "PhoneAccount registered successfully: $PHONE_ACCOUNT_LABEL")
            
            // 登録確認
            val registeredAccounts = telecomManager.selfManagedPhoneAccounts
            val isRegistered = registeredAccounts.any { it.id == PHONE_ACCOUNT_ID }
            
            if (isRegistered) {
                Log.i(TAG, "PhoneAccount registration verified")
            } else {
                Log.w(TAG, "PhoneAccount registration could not be verified")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register PhoneAccount", e)
        }
    }

    /**
     * PhoneAccountの登録を解除
     */
    fun unregisterPhoneAccount(context: Context) {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (telecomManager == null) {
                Log.e(TAG, "TelecomManager not available for unregistration")
                return
            }

            val phoneAccountHandle = getPhoneAccountHandle(context)
            telecomManager.unregisterPhoneAccount(phoneAccountHandle)
            
            Log.i(TAG, "PhoneAccount unregistered: $PHONE_ACCOUNT_LABEL")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister PhoneAccount", e)
        }
    }
}