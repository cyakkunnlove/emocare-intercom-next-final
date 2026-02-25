package com.emocare.intercom.next.data.repository

import com.emocare.intercom.next.data.local.TokenManager
import com.emocare.intercom.next.data.local.database.dao.UserDao
import com.emocare.intercom.next.data.network.SupabaseApiService
import com.emocare.intercom.next.domain.model.User
import com.emocare.intercom.next.domain.model.AuthState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 認証Repository実装
 * 
 * LINEレベルの品質実現のための認証管理:
 * - セキュアなトークン管理
 * - 自動トークンリフレッシュ
 * - オフライン対応
 * - セッション状態の一元管理
 */
@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val tokenManager: TokenManager,
    private val userDao: UserDao,
    private val supabaseApiService: SupabaseApiService
) : AuthRepository {

    override val authState: Flow<AuthState> = combine(
        tokenManager.authState,
        userDao.observeUser(getCurrentUserId() ?: "")
    ) { tokenAuthState, user ->
        tokenAuthState.copy(user = user)
    }

    override suspend fun signIn(email: String, password: String): Result<AuthState> {
        return try {
            // バリデーション
            if (email.isBlank() || password.isBlank()) {
                return Result.failure(AuthException.InvalidCredentials("メールアドレスとパスワードを入力してください"))
            }

            // Supabase認証APIを呼び出し
            val authResponse = supabaseApiService.signIn(
                SignInRequest(email = email, password = password)
            )

            if (authResponse.isSuccessful) {
                val authData = authResponse.body() ?: throw AuthException.ServerError("認証レスポンスが空です")

                // トークンを保存
                tokenManager.saveTokens(
                    accessToken = authData.accessToken,
                    refreshToken = authData.refreshToken,
                    expiresAt = authData.expiresAt,
                    tokenType = authData.tokenType,
                    userId = authData.user.id
                )

                // ユーザー情報をローカルDBに保存
                userDao.insertUser(authData.user)

                val newAuthState = AuthState(
                    isAuthenticated = true,
                    user = authData.user,
                    accessToken = authData.accessToken,
                    refreshToken = authData.refreshToken,
                    expiresAt = authData.expiresAt
                )

                Result.success(newAuthState)
            } else {
                val errorBody = authResponse.errorBody()?.string()
                Result.failure(AuthException.InvalidCredentials(errorBody ?: "認証に失敗しました"))
            }
        } catch (e: Exception) {
            Result.failure(when (e) {
                is AuthException -> e
                else -> AuthException.NetworkError("ネットワークエラー: ${e.message}")
            })
        }
    }

    override suspend fun signOut(): Result<Unit> {
        return try {
            val refreshToken = tokenManager.getRefreshToken()
            
            // サーバー側のセッション終了
            refreshToken?.let {
                try {
                    supabaseApiService.signOut(SignOutRequest(refreshToken = it))
                } catch (e: Exception) {
                    // サーバー側のエラーは無視（ローカルのセッションは終了）
                    android.util.Log.w("AuthRepository", "Server sign out failed", e)
                }
            }

            // ローカルのデータをクリア
            tokenManager.clearTokens()
            // ユーザー情報はキャッシュとして保持（次回ログイン高速化）

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(AuthException.NetworkError("サインアウトに失敗しました: ${e.message}"))
        }
    }

    override suspend fun refreshToken(): Result<AuthState> {
        return try {
            val refreshToken = tokenManager.getRefreshToken()
                ?: return Result.failure(AuthException.TokenExpired("リフレッシュトークンがありません"))

            val response = supabaseApiService.refreshToken(
                RefreshTokenRequest(refreshToken = refreshToken)
            )

            if (response.isSuccessful) {
                val authData = response.body() ?: throw AuthException.ServerError("トークンリフレッシュレスポンスが空です")

                // 新しいトークンを保存
                tokenManager.updateAccessToken(
                    newAccessToken = authData.accessToken,
                    newExpiresAt = authData.expiresAt
                )

                val currentUser = getCurrentUser()
                val newAuthState = AuthState(
                    isAuthenticated = true,
                    user = currentUser,
                    accessToken = authData.accessToken,
                    refreshToken = refreshToken, // リフレッシュトークンは通常変更されない
                    expiresAt = authData.expiresAt
                )

                Result.success(newAuthState)
            } else {
                // トークンが無効な場合はログアウト
                tokenManager.clearTokens()
                Result.failure(AuthException.TokenExpired("トークンの更新に失敗しました"))
            }
        } catch (e: Exception) {
            Result.failure(AuthException.NetworkError("トークン更新エラー: ${e.message}"))
        }
    }

    override suspend fun getCurrentUser(): User? {
        val userId = getCurrentUserId() ?: return null
        return userDao.getUserById(userId)
    }

    override suspend fun getCurrentUserId(): String? {
        return tokenManager.getUserId()
    }

    override suspend fun isAuthenticated(): Boolean {
        return tokenManager.isAuthenticated && tokenManager.isTokenValid
    }

    override suspend fun validateSession(): Result<Boolean> {
        return try {
            if (!tokenManager.isAuthenticated) {
                Result.success(false)
            } else if (tokenManager.needsTokenRefresh) {
                // 自動トークンリフレッシュ
                val refreshResult = refreshToken()
                Result.success(refreshResult.isSuccess)
            } else {
                Result.success(tokenManager.isTokenValid)
            }
        } catch (e: Exception) {
            Result.failure(AuthException.NetworkError("セッション検証エラー: ${e.message}"))
        }
    }

    override suspend fun updateUserProfile(user: User): Result<User> {
        return try {
            val response = supabaseApiService.updateUserProfile(
                userId = user.id,
                request = UpdateUserProfileRequest(
                    name = user.name,
                    email = user.email
                )
            )

            if (response.isSuccessful) {
                val updatedUser = response.body() ?: throw AuthException.ServerError("プロフィール更新レスポンスが空です")
                
                // ローカルDBも更新
                userDao.updateUser(updatedUser)
                
                Result.success(updatedUser)
            } else {
                Result.failure(AuthException.ServerError("プロフィール更新に失敗しました"))
            }
        } catch (e: Exception) {
            Result.failure(AuthException.NetworkError("プロフィール更新エラー: ${e.message}"))
        }
    }

    override suspend fun deleteAccount(): Result<Unit> {
        return try {
            val userId = getCurrentUserId() ?: return Result.failure(AuthException.NotAuthenticated("ユーザーが認証されていません"))
            
            val response = supabaseApiService.deleteUser(userId)
            
            if (response.isSuccessful) {
                // ローカルデータをクリア
                tokenManager.clearTokens()
                userDao.deleteUserById(userId)
                
                Result.success(Unit)
            } else {
                Result.failure(AuthException.ServerError("アカウント削除に失敗しました"))
            }
        } catch (e: Exception) {
            Result.failure(AuthException.NetworkError("アカウント削除エラー: ${e.message}"))
        }
    }
}

/**
 * 認証関連の例外クラス
 */
sealed class AuthException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class InvalidCredentials(message: String) : AuthException(message)
    class TokenExpired(message: String) : AuthException(message)
    class NotAuthenticated(message: String) : AuthException(message)
    class NetworkError(message: String) : AuthException(message)
    class ServerError(message: String) : AuthException(message)
}

/**
 * API リクエスト・レスポンス データクラス
 */
data class SignInRequest(
    val email: String,
    val password: String
)

data class SignInResponse(
    val accessToken: String,
    val refreshToken: String,
    val tokenType: String,
    val expiresAt: java.time.LocalDateTime,
    val user: User
)

data class SignOutRequest(
    val refreshToken: String
)

data class RefreshTokenRequest(
    val refreshToken: String
)

data class RefreshTokenResponse(
    val accessToken: String,
    val expiresAt: java.time.LocalDateTime
)

data class UpdateUserProfileRequest(
    val name: String?,
    val email: String
)