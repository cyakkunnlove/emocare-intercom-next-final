package com.emocare.intercom.next.domain.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

/**
 * 通話記録モデル
 * 
 * VoIP通話とPTT通信の履歴を記録
 */
@Entity(tableName = "call_records")
data class CallRecord(
    @PrimaryKey
    val id: String,
    
    val channelId: String,
    
    val callerId: String,
    
    val callerName: String,
    
    val callType: CallType,
    
    val startTime: LocalDateTime,
    
    val endTime: LocalDateTime? = null,
    
    val isEmergency: Boolean = false,
    
    val connectionQuality: ConnectionQuality = ConnectionQuality.GOOD,
    
    val participantsCount: Int = 0,
    
    val isSuccessful: Boolean = true,
    
    val failureReason: String? = null
) {
    /**
     * 通話継続時間を取得
     */
    val duration: java.time.Duration
        get() = if (endTime != null) {
            java.time.Duration.between(startTime, endTime)
        } else {
            java.time.Duration.ZERO
        }
    
    /**
     * 通話が終了しているかチェック
     */
    val isCompleted: Boolean
        get() = endTime != null
    
    /**
     * 通話が進行中かチェック
     */
    val isActive: Boolean
        get() = endTime == null && isSuccessful
    
    /**
     * 表示用の継続時間文字列を取得
     */
    val durationDisplayText: String
        get() {
            val dur = duration
            val minutes = dur.toMinutes()
            val seconds = dur.seconds % 60
            
            return when {
                minutes > 0 -> "${minutes}分${seconds}秒"
                seconds > 0 -> "${seconds}秒"
                else -> "< 1秒"
            }
        }
}

/**
 * 通話タイプ定義
 */
enum class CallType(
    val displayName: String,
    val iconName: String
) {
    VOIP("音声通話", "phone"),
    PTT("Push-to-Talk", "mic"),
    VIDEO("ビデオ通話", "videocam"); // 将来機能
    
    companion object {
        fun fromString(value: String): CallType {
            return entries.find { 
                it.name.equals(value, ignoreCase = true) 
            } ?: VOIP
        }
    }
}

/**
 * 接続品質定義
 */
enum class ConnectionQuality(
    val displayName: String,
    val colorName: String
) {
    EXCELLENT("優秀", "green"),
    GOOD("良好", "light_green"), 
    FAIR("普通", "orange"),
    POOR("悪い", "red"),
    FAILED("失敗", "gray");
    
    companion object {
        fun fromLatency(latencyMs: Int): ConnectionQuality {
            return when {
                latencyMs <= 50 -> EXCELLENT
                latencyMs <= 100 -> GOOD
                latencyMs <= 200 -> FAIR
                latencyMs <= 500 -> POOR
                else -> FAILED
            }
        }
    }
}

/**
 * 通話参加者情報
 */
data class CallParticipant(
    val userId: String,
    val userName: String,
    val userRole: UserRole,
    val joinTime: LocalDateTime,
    val leaveTime: LocalDateTime? = null,
    val wasInitiator: Boolean = false,
    val audioQualityScore: Float = 0f // 0.0-1.0
) {
    /**
     * 参加継続時間を取得
     */
    val participationDuration: java.time.Duration
        get() = if (leaveTime != null) {
            java.time.Duration.between(joinTime, leaveTime)
        } else {
            java.time.Duration.between(joinTime, LocalDateTime.now())
        }
    
    /**
     * まだ通話に参加中かチェック
     */
    val isStillActive: Boolean
        get() = leaveTime == null
}

/**
 * 通話統計情報
 */
data class CallStatistics(
    val totalCalls: Int = 0,
    val todayCalls: Int = 0,
    val weekCalls: Int = 0,
    val monthCalls: Int = 0,
    val emergencyCalls: Int = 0,
    val averageDuration: java.time.Duration = java.time.Duration.ZERO,
    val successRate: Float = 0f, // 0.0-1.0
    val mostActiveChannel: String? = null,
    val peakHour: Int = 12 // 0-23
) {
    /**
     * 成功率を百分率で取得
     */
    val successRatePercentage: Int
        get() = (successRate * 100).toInt()
}

/**
 * 通話品質メトリクス
 */
data class CallQualityMetrics(
    val callId: String,
    val averageLatency: Int, // ミリ秒
    val packetLoss: Float, // 0.0-1.0
    val jitter: Int, // ミリ秒
    val audioLevel: Float, // 0.0-1.0
    val connectionStability: Float, // 0.0-1.0
    val recordedAt: LocalDateTime
) {
    /**
     * 全体的な品質スコアを計算
     */
    val overallQualityScore: Float
        get() {
            val latencyScore = when {
                averageLatency <= 50 -> 1.0f
                averageLatency <= 100 -> 0.8f
                averageLatency <= 200 -> 0.6f
                averageLatency <= 500 -> 0.3f
                else -> 0.1f
            }
            
            val packetLossScore = (1.0f - packetLoss).coerceAtLeast(0f)
            val jitterScore = when {
                jitter <= 10 -> 1.0f
                jitter <= 30 -> 0.7f
                jitter <= 50 -> 0.5f
                else -> 0.2f
            }
            
            return (latencyScore + packetLossScore + jitterScore + connectionStability) / 4f
        }
    
    /**
     * 品質レベルを取得
     */
    val qualityLevel: ConnectionQuality
        get() = when {
            overallQualityScore >= 0.8f -> ConnectionQuality.EXCELLENT
            overallQualityScore >= 0.6f -> ConnectionQuality.GOOD
            overallQualityScore >= 0.4f -> ConnectionQuality.FAIR
            overallQualityScore >= 0.2f -> ConnectionQuality.POOR
            else -> ConnectionQuality.FAILED
        }
}