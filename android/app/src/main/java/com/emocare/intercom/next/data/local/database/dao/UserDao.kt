package com.emocare.intercom.next.data.local.database.dao

import androidx.room.*
import com.emocare.intercom.next.domain.model.User
import kotlinx.coroutines.flow.Flow

/**
 * ユーザー情報のデータアクセスオブジェクト
 * 
 * LINEレベルの品質実現のためのローカルデータアクセス最適化:
 * - Flow による反応性の高いデータ監視
 * - 効率的なクエリによる高速データ取得
 * - 適切なインデックス設定
 */
@Dao
interface UserDao {

    /**
     * 全ユーザーを監視
     */
    @Query("SELECT * FROM users ORDER BY name ASC")
    fun observeAllUsers(): Flow<List<User>>

    /**
     * 施設内のユーザーを監視
     */
    @Query("SELECT * FROM users WHERE facilityId = :facilityId AND isActive = 1 ORDER BY name ASC")
    fun observeUsersByFacility(facilityId: String): Flow<List<User>>

    /**
     * 特定のユーザーを監視
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    fun observeUser(userId: String): Flow<User?>

    /**
     * ユーザーIDで取得
     */
    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): User?

    /**
     * メールアドレスでユーザー取得
     */
    @Query("SELECT * FROM users WHERE email = :email")
    suspend fun getUserByEmail(email: String): User?

    /**
     * 施設内のアクティブユーザーを取得
     */
    @Query("SELECT * FROM users WHERE facilityId = :facilityId AND isActive = 1")
    suspend fun getActiveUsersByFacility(facilityId: String): List<User>

    /**
     * 管理者権限を持つユーザーを取得
     */
    @Query("SELECT * FROM users WHERE facilityId = :facilityId AND role IN ('ADMIN', 'MANAGER') AND isActive = 1")
    suspend fun getManagementUsers(facilityId: String): List<User>

    /**
     * ユーザーを挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: User)

    /**
     * 複数ユーザーを挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<User>)

    /**
     * ユーザー情報を更新
     */
    @Update
    suspend fun updateUser(user: User)

    /**
     * ユーザーを削除
     */
    @Delete
    suspend fun deleteUser(user: User)

    /**
     * ユーザーIDで削除
     */
    @Query("DELETE FROM users WHERE id = :userId")
    suspend fun deleteUserById(userId: String)

    /**
     * 非アクティブ化（論理削除）
     */
    @Query("UPDATE users SET isActive = 0 WHERE id = :userId")
    suspend fun deactivateUser(userId: String)

    /**
     * 施設内の全ユーザーを削除
     */
    @Query("DELETE FROM users WHERE facilityId = :facilityId")
    suspend fun deleteUsersByFacility(facilityId: String)

    /**
     * ユーザー数をカウント
     */
    @Query("SELECT COUNT(*) FROM users WHERE facilityId = :facilityId AND isActive = 1")
    suspend fun getUserCount(facilityId: String): Int

    /**
     * ロール別ユーザー数をカウント
     */
    @Query("SELECT COUNT(*) FROM users WHERE facilityId = :facilityId AND role = :role AND isActive = 1")
    suspend fun getUserCountByRole(facilityId: String, role: String): Int

    /**
     * ユーザー検索（名前・メールアドレス）
     */
    @Query("""
        SELECT * FROM users 
        WHERE facilityId = :facilityId 
        AND isActive = 1 
        AND (name LIKE '%' || :query || '%' OR email LIKE '%' || :query || '%')
        ORDER BY name ASC
    """)
    suspend fun searchUsers(facilityId: String, query: String): List<User>

    /**
     * 最近作成されたユーザーを取得
     */
    @Query("SELECT * FROM users WHERE facilityId = :facilityId AND isActive = 1 ORDER BY createdAt DESC LIMIT :limit")
    suspend fun getRecentUsers(facilityId: String, limit: Int = 10): List<User>

    /**
     * キャッシュをクリア
     */
    @Query("DELETE FROM users")
    suspend fun clearAll()
}