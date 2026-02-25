package com.emocare.intercom.next.data.repository

import com.emocare.intercom.next.domain.model.User
import com.emocare.intercom.next.domain.model.AuthState
import kotlinx.coroutines.flow.Flow

/**
 * 認証Repository インターフェース
 * 
 * LINEレベルの品質実現のための認証管理:
 * - 統一されたインターフェース
 * - テスタビリティの向上
 * - 実装の抽象化
 */
interface AuthRepository {

    /**
     * 認証状態を監視
     */
    val authState: Flow<AuthState>

    /**
     * サインイン
     */
    suspend fun signIn(email: String, password: String): Result<AuthState>

    /**
     * サインアウト
     */
    suspend fun signOut(): Result<Unit>

    /**
     * トークンをリフレッシュ
     */
    suspend fun refreshToken(): Result<AuthState>

    /**
     * 現在のユーザーを取得
     */
    suspend fun getCurrentUser(): User?

    /**
     * 現在のユーザーIDを取得
     */
    suspend fun getCurrentUserId(): String?

    /**
     * 認証されているかチェック
     */
    suspend fun isAuthenticated(): Boolean

    /**
     * セッションの有効性を検証
     */
    suspend fun validateSession(): Result<Boolean>

    /**
     * ユーザープロフィールを更新
     */
    suspend fun updateUserProfile(user: User): Result<User>

    /**
     * アカウントを削除
     */
    suspend fun deleteAccount(): Result<Unit>
}