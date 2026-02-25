package com.emocare.intercom.next.domain.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

/**
 * チャンネルモデル
 * 
 * 施設内の通信チャンネル（部屋別・機能別）を表現
 */
@Entity(tableName = "channels")
data class Channel(
    @PrimaryKey
    val id: String,
    
    val name: String,
    
    val description: String = "",
    
    val facilityId: String,
    
    val isEmergencyChannel: Boolean = false,
    
    val isActive: Boolean = true,
    
    val maxParticipants: Int = 50,
    
    val allowPTT: Boolean = true,
    
    val allowVoIP: Boolean = true,
    
    val createdAt: LocalDateTime,
    
    val updatedAt: LocalDateTime
) {
    /**
     * チャンネルタイプを取得
     */
    val channelType: ChannelType
        get() = when {
            isEmergencyChannel -> ChannelType.EMERGENCY
            name.contains("ナースステーション", ignoreCase = true) -> ChannelType.NURSE_STATION
            name.contains("管理", ignoreCase = true) -> ChannelType.MANAGEMENT
            else -> ChannelType.GENERAL
        }
    
    /**
     * 表示用のアイコン名を取得
     */
    val iconName: String
        get() = when (channelType) {
            ChannelType.EMERGENCY -> "emergency"
            ChannelType.NURSE_STATION -> "medical_services"
            ChannelType.MANAGEMENT -> "admin_panel_settings"
            ChannelType.GENERAL -> "forum"
        }
}

/**
 * チャンネルタイプ定義
 */
enum class ChannelType(
    val displayName: String,
    val priority: Int
) {
    EMERGENCY("緊急", 10),
    NURSE_STATION("ナースステーション", 8),
    MANAGEMENT("管理", 6),
    GENERAL("一般", 3)
}

/**
 * チャンネル参加者情報
 */
data class ChannelParticipant(
    val userId: String,
    val channelId: String,
    val userName: String,
    val userRole: UserRole,
    val joinedAt: LocalDateTime,
    val isOnline: Boolean = false,
    val isSpeaking: Boolean = false,
    val audioLevel: Float = 0f
) {
    /**
     * 参加継続時間を取得
     */
    val participationDuration: java.time.Duration
        get() = java.time.Duration.between(joinedAt, LocalDateTime.now())
}

/**
 * チャンネル統計情報
 */
data class ChannelStatistics(
    val channelId: String,
    val totalParticipants: Int = 0,
    val onlineParticipants: Int = 0,
    val todayCallsCount: Int = 0,
    val weeklyCallsCount: Int = 0,
    val averageCallDuration: java.time.Duration = java.time.Duration.ZERO,
    val lastActivityAt: LocalDateTime? = null
) {
    /**
     * チャンネルの活動レベルを取得
     */
    val activityLevel: ActivityLevel
        get() = when {
            onlineParticipants >= 5 -> ActivityLevel.HIGH
            onlineParticipants >= 2 -> ActivityLevel.MEDIUM
            onlineParticipants >= 1 -> ActivityLevel.LOW
            else -> ActivityLevel.INACTIVE
        }
}

enum class ActivityLevel(val displayName: String) {
    HIGH("活発"),
    MEDIUM("普通"),
    LOW("少なめ"),
    INACTIVE("非活動")
}

/**
 * チャンネル更新情報（リアルタイム用）
 */
sealed class ChannelUpdate {
    data class ParticipantJoined(
        val channelId: String,
        val participant: ChannelParticipant
    ) : ChannelUpdate()
    
    data class ParticipantLeft(
        val channelId: String,
        val userId: String
    ) : ChannelUpdate()
    
    data class SpeakingStateChanged(
        val channelId: String,
        val userId: String,
        val isSpeaking: Boolean
    ) : ChannelUpdate()
    
    data class CallStarted(
        val channelId: String,
        val callId: String,
        val initiatorId: String,
        val isEmergency: Boolean
    ) : ChannelUpdate()
    
    data class CallEnded(
        val channelId: String,
        val callId: String
    ) : ChannelUpdate()
    
    data class EmergencyActivated(
        val channelId: String,
        val activatedBy: String
    ) : ChannelUpdate()
}