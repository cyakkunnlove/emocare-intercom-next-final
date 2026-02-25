package com.emocare.intercom.next.system.telecom

import android.os.Bundle
import android.util.Log
import java.util.UUID

/**
 * EmoCare通話メタデータ
 * 
 * 通話に関する情報を管理:
 * - 通話識別情報
 * - 参加者情報  
 * - 通話タイプ
 * - Bundle変換サポート
 */
data class EmoCareCallMetadata(
    val callId: String,
    val targetId: String,
    val callerName: String,
    val targetName: String,
    val channelId: String?,
    val channelName: String?,
    val isIncoming: Boolean,
    val isEmergency: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
) {
    
    companion object {
        private const val TAG = "EmoCareCallMetadata"
        
        // Bundle keys
        private const val KEY_CALL_ID = "call_id"
        private const val KEY_TARGET_ID = "target_id"
        private const val KEY_CALLER_NAME = "caller_name"
        private const val KEY_TARGET_NAME = "target_name"
        private const val KEY_CHANNEL_ID = "channel_id"
        private const val KEY_CHANNEL_NAME = "channel_name"
        private const val KEY_IS_INCOMING = "is_incoming"
        private const val KEY_IS_EMERGENCY = "is_emergency"
        private const val KEY_TIMESTAMP = "timestamp"

        /**
         * Bundleからメタデータを復元
         */
        fun fromBundle(extras: Bundle?, isIncoming: Boolean): EmoCareCallMetadata? {
            if (extras == null) {
                Log.w(TAG, "No extras bundle provided")
                return null
            }

            return try {
                EmoCareCallMetadata(
                    callId = extras.getString(KEY_CALL_ID) ?: UUID.randomUUID().toString(),
                    targetId = extras.getString(KEY_TARGET_ID) ?: "",
                    callerName = extras.getString(KEY_CALLER_NAME) ?: "Unknown",
                    targetName = extras.getString(KEY_TARGET_NAME) ?: "Unknown",
                    channelId = extras.getString(KEY_CHANNEL_ID),
                    channelName = extras.getString(KEY_CHANNEL_NAME),
                    isIncoming = extras.getBoolean(KEY_IS_INCOMING, isIncoming),
                    isEmergency = extras.getBoolean(KEY_IS_EMERGENCY, false),
                    timestamp = extras.getLong(KEY_TIMESTAMP, System.currentTimeMillis())
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse metadata from bundle", e)
                null
            }
        }

        /**
         * 発信通話用のメタデータ作成
         */
        fun createOutgoing(
            targetId: String,
            targetName: String,
            channelId: String? = null,
            channelName: String? = null,
            isEmergency: Boolean = false
        ): EmoCareCallMetadata {
            return EmoCareCallMetadata(
                callId = UUID.randomUUID().toString(),
                targetId = targetId,
                callerName = "You", // TODO: 実際のユーザー名を取得
                targetName = targetName,
                channelId = channelId,
                channelName = channelName,
                isIncoming = false,
                isEmergency = isEmergency
            )
        }

        /**
         * 着信通話用のメタデータ作成
         */
        fun createIncoming(
            callId: String,
            callerId: String,
            callerName: String,
            channelId: String? = null,
            channelName: String? = null,
            isEmergency: Boolean = false
        ): EmoCareCallMetadata {
            return EmoCareCallMetadata(
                callId = callId,
                targetId = callerId,
                callerName = callerName,
                targetName = "You", // TODO: 実際のユーザー名を取得
                channelId = channelId,
                channelName = channelName,
                isIncoming = true,
                isEmergency = isEmergency
            )
        }
    }

    /**
     * メタデータをBundleに変換
     */
    fun toBundle(): Bundle {
        return Bundle().apply {
            putString(KEY_CALL_ID, callId)
            putString(KEY_TARGET_ID, targetId)
            putString(KEY_CALLER_NAME, callerName)
            putString(KEY_TARGET_NAME, targetName)
            putString(KEY_CHANNEL_ID, channelId)
            putString(KEY_CHANNEL_NAME, channelName)
            putBoolean(KEY_IS_INCOMING, isIncoming)
            putBoolean(KEY_IS_EMERGENCY, isEmergency)
            putLong(KEY_TIMESTAMP, timestamp)
        }
    }

    /**
     * 表示用の通話名を取得
     */
    fun getDisplayName(): String {
        return if (channelName != null) {
            "$targetName ($channelName)"
        } else {
            targetName
        }
    }

    /**
     * 通話タイプの説明を取得
     */
    fun getCallTypeDescription(): String {
        return when {
            isEmergency -> "緊急通話"
            channelId != null -> "チャンネル通話"
            else -> "直接通話"
        }
    }
}