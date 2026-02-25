package com.emocare.intercom.next.data.local

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 認証トークン管理クラス
 * 
 * LINEレベルの品質実現のためのセキュアトークン管理:
 * - 暗号化されたローカルストレージ
 * - 自動トークンリフレッシュ
 * - セッション有効性チェック
 * - セキュアな削除処理
 */
@Singleton
class TokenManager @Inject constructor(
    private val encryptedPreferencesManager: EncryptedPreferencesManager
) {
    
    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token" 
        private const val KEY_EXPIRES_AT = "expires_at"
        private const val KEY_TOKEN_TYPE = "token_type"
        private const val KEY_USER_ID = "user_id"
        
        private val DATE_TIME_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME
    }

    private val _authState = MutableStateFlow(loadAuthState())
    val authState: Flow<AuthState> = _authState.asStateFlow()

    /**
     * 現在の認証状態を取得
     */
    val currentAuthState: AuthState
        get() = _authState.value

    /**
     * 認証されているかチェック
     */
    val isAuthenticated: Boolean
        get() = currentAuthState.isAuthenticated

    /**
     * トークンが有効かチェック
     */
    val isTokenValid: Boolean
        get() = currentAuthState.isTokenValid

    /**
     * トークンリフレッシュが必要かチェック
     */
    val needsTokenRefresh: Boolean
        get() = currentAuthState.needsTokenRefresh

    /**
     * アクセストークンを保存
     */
    suspend fun saveTokens(
        accessToken: String,
        refreshToken: String,
        expiresAt: LocalDateTime,
        tokenType: String = "Bearer",
        userId: String
    ) {
        encryptedPreferencesManager.saveString(KEY_ACCESS_TOKEN, accessToken)
        encryptedPreferencesManager.saveString(KEY_REFRESH_TOKEN, refreshToken)
        encryptedPreferencesManager.saveString(KEY_EXPIRES_AT, expiresAt.format(DATE_TIME_FORMATTER))
        encryptedPreferencesManager.saveString(KEY_TOKEN_TYPE, tokenType)
        encryptedPreferencesManager.saveString(KEY_USER_ID, userId)
        
        _authState.value = loadAuthState()
    }

    /**
     * アクセストークンを取得
     */
    suspend fun getAccessToken(): String? {
        return encryptedPreferencesManager.getString(KEY_ACCESS_TOKEN)
    }

    /**
     * リフレッシュトークンを取得
     */
    suspend fun getRefreshToken(): String? {
        return encryptedPreferencesManager.getString(KEY_REFRESH_TOKEN)
    }

    /**
     * トークンタイプを取得
     */
    suspend fun getTokenType(): String {
        return encryptedPreferencesManager.getString(KEY_TOKEN_TYPE) ?: "Bearer"
    }

    /**
     * ユーザーIDを取得
     */
    suspend fun getUserId(): String? {
        return encryptedPreferencesManager.getString(KEY_USER_ID)
    }

    /**
     * 有効期限を取得
     */
    suspend fun getExpiresAt(): LocalDateTime? {
        val expiresAtString = encryptedPreferencesManager.getString(KEY_EXPIRES_AT)
        return expiresAtString?.let { 
            try {
                LocalDateTime.parse(it, DATE_TIME_FORMATTER)
            } catch (e: Exception) {
                null
            }
        }
    }

    /**
     * Authorization Headerを生成
     */
    suspend fun getAuthorizationHeader(): String? {
        val accessToken = getAccessToken() ?: return null
        val tokenType = getTokenType()
        return "$tokenType $accessToken"
    }

    /**
     * トークンをクリア
     */
    suspend fun clearTokens() {
        encryptedPreferencesManager.removeKey(KEY_ACCESS_TOKEN)
        encryptedPreferencesManager.removeKey(KEY_REFRESH_TOKEN)
        encryptedPreferencesManager.removeKey(KEY_EXPIRES_AT)
        encryptedPreferencesManager.removeKey(KEY_TOKEN_TYPE)
        encryptedPreferencesManager.removeKey(KEY_USER_ID)
        
        _authState.value = AuthState()
    }

    /**
     * 新しいアクセストークンで更新（リフレッシュ時）
     */
    suspend fun updateAccessToken(
        newAccessToken: String,
        newExpiresAt: LocalDateTime
    ) {
        encryptedPreferencesManager.saveString(KEY_ACCESS_TOKEN, newAccessToken)
        encryptedPreferencesManager.saveString(KEY_EXPIRES_AT, newExpiresAt.format(DATE_TIME_FORMATTER))
        
        _authState.value = loadAuthState()
    }

    /**
     * トークンの残り有効時間を取得（分）
     */
    suspend fun getRemainingTokenTimeMinutes(): Long? {
        val expiresAt = getExpiresAt() ?: return null
        val now = LocalDateTime.now()
        
        return if (now.isBefore(expiresAt)) {
            java.time.Duration.between(now, expiresAt).toMinutes()
        } else {
            0L
        }
    }

    /**
     * トークンの有効性をチェック
     */
    suspend fun validateToken(): Boolean {
        val accessToken = getAccessToken() ?: return false
        val expiresAt = getExpiresAt() ?: return false
        val now = LocalDateTime.now()
        
        return now.isBefore(expiresAt) && accessToken.isNotBlank()
    }

    /**
     * ストレージから認証状態を読み込み
     */
    private fun loadAuthState(): AuthState {
        return try {
            val accessToken = runCatching { 
                kotlinx.coroutines.runBlocking { getAccessToken() }
            }.getOrNull()
            
            val refreshToken = runCatching { 
                kotlinx.coroutines.runBlocking { getRefreshToken() }
            }.getOrNull()
            
            val expiresAt = runCatching { 
                kotlinx.coroutines.runBlocking { getExpiresAt() }
            }.getOrNull()

            AuthState(
                isAuthenticated = !accessToken.isNullOrBlank(),
                user = null, // ユーザー情報は別途読み込み
                accessToken = accessToken,
                refreshToken = refreshToken,
                expiresAt = expiresAt
            )
        } catch (e: Exception) {
            AuthState()
        }
    }

    /**
     * セキュリティのためのトークンハッシュ生成
     */
    private fun generateTokenHash(token: String): String {
        return token.hashCode().toString()
    }
}

/**
 * 認証状態データクラス（再定義を避けるためimport）
 */
typealias AuthState = com.emocare.intercom.next.domain.model.AuthState