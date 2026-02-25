package com.emocare.intercom.next.domain.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

/**
 * ユーザーモデル
 * 
 * EmoCare施設のユーザー（職員・管理者・ゲスト）を表現
 */
@Entity(tableName = "users")
data class User(
    @PrimaryKey
    val id: String,
    
    val email: String,
    
    val name: String?,
    
    val facilityId: String?,
    
    val role: UserRole,
    
    val isActive: Boolean = true,
    
    val createdAt: LocalDateTime,
    
    val updatedAt: LocalDateTime
) {
    /**
     * 表示用の名前を取得
     */
    val displayName: String
        get() = name?.takeIf { it.isNotBlank() } ?: email.substringBefore('@')
    
    /**
     * ユーザーが管理権限を持っているかチェック
     */
    val hasManagementRole: Boolean
        get() = role == UserRole.ADMIN || role == UserRole.MANAGER
    
    /**
     * 緊急チャンネルへのアクセス権があるかチェック  
     */
    val canAccessEmergencyChannels: Boolean
        get() = hasManagementRole || role == UserRole.STAFF
}

/**
 * ユーザーロール定義
 */
enum class UserRole(
    val displayName: String,
    val priority: Int
) {
    ADMIN("管理者", 10),
    MANAGER("施設管理者", 8), 
    STAFF("スタッフ", 5),
    GUEST("ゲスト", 1);
    
    companion object {
        fun fromString(value: String): UserRole {
            return entries.find { 
                it.name.equals(value, ignoreCase = true) 
            } ?: GUEST
        }
    }
}

/**
 * ユーザーのオンライン状態
 */
data class UserPresence(
    val userId: String,
    val isOnline: Boolean,
    val lastSeen: LocalDateTime?,
    val currentChannelId: String? = null,
    val status: PresenceStatus = PresenceStatus.AVAILABLE
)

enum class PresenceStatus(val displayName: String) {
    AVAILABLE("対応可能"),
    BUSY("取り込み中"),
    IN_CALL("通話中"),
    AWAY("離席中"),
    DO_NOT_DISTURB("応答不可"),
    OFFLINE("オフライン")
}

/**
 * 認証状態を表すデータクラス
 */
data class AuthState(
    val isAuthenticated: Boolean = false,
    val user: User? = null,
    val accessToken: String? = null,
    val refreshToken: String? = null,
    val expiresAt: LocalDateTime? = null
) {
    val isTokenValid: Boolean
        get() = accessToken != null && 
                expiresAt != null && 
                LocalDateTime.now().isBefore(expiresAt)
    
    val needsTokenRefresh: Boolean
        get() = accessToken != null && 
                expiresAt != null && 
                LocalDateTime.now().plusMinutes(5).isAfter(expiresAt)
}