package com.emocare.intercom.next.data.local.database.dao

import androidx.room.*
import com.emocare.intercom.next.domain.model.Channel
import kotlinx.coroutines.flow.Flow

/**
 * チャンネル情報のデータアクセスオブジェクト
 * 
 * LINEレベルの品質実現のための最適化:
 * - リアルタイムデータ監視による即座のUI更新
 * - 緊急チャンネルの優先表示
 * - 効率的なソートとフィルタリング
 */
@Dao
interface ChannelDao {

    /**
     * 施設内の全チャンネルを監視（緊急チャンネル優先）
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId AND isActive = 1 
        ORDER BY isEmergencyChannel DESC, name ASC
    """)
    fun observeChannelsByFacility(facilityId: String): Flow<List<Channel>>

    /**
     * 特定チャンネルを監視
     */
    @Query("SELECT * FROM channels WHERE id = :channelId")
    fun observeChannel(channelId: String): Flow<Channel?>

    /**
     * 緊急チャンネルのみ監視
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId AND isEmergencyChannel = 1 AND isActive = 1 
        ORDER BY name ASC
    """)
    fun observeEmergencyChannels(facilityId: String): Flow<List<Channel>>

    /**
     * 一般チャンネルのみ監視
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId AND isEmergencyChannel = 0 AND isActive = 1 
        ORDER BY name ASC
    """)
    fun observeRegularChannels(facilityId: String): Flow<List<Channel>>

    /**
     * チャンネルIDで取得
     */
    @Query("SELECT * FROM channels WHERE id = :channelId")
    suspend fun getChannelById(channelId: String): Channel?

    /**
     * 施設内のアクティブチャンネルを取得
     */
    @Query("SELECT * FROM channels WHERE facilityId = :facilityId AND isActive = 1 ORDER BY isEmergencyChannel DESC, name ASC")
    suspend fun getActiveChannelsByFacility(facilityId: String): List<Channel>

    /**
     * 緊急チャンネルを取得
     */
    @Query("SELECT * FROM channels WHERE facilityId = :facilityId AND isEmergencyChannel = 1 AND isActive = 1")
    suspend fun getEmergencyChannels(facilityId: String): List<Channel>

    /**
     * PTT対応チャンネルを取得
     */
    @Query("SELECT * FROM channels WHERE facilityId = :facilityId AND allowPTT = 1 AND isActive = 1 ORDER BY name ASC")
    suspend fun getPTTEnabledChannels(facilityId: String): List<Channel>

    /**
     * VoIP対応チャンネルを取得
     */
    @Query("SELECT * FROM channels WHERE facilityId = :facilityId AND allowVoIP = 1 AND isActive = 1 ORDER BY name ASC")
    suspend fun getVoIPEnabledChannels(facilityId: String): List<Channel>

    /**
     * チャンネルを挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChannel(channel: Channel)

    /**
     * 複数チャンネルを挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChannels(channels: List<Channel>)

    /**
     * チャンネル情報を更新
     */
    @Update
    suspend fun updateChannel(channel: Channel)

    /**
     * チャンネルを削除
     */
    @Delete
    suspend fun deleteChannel(channel: Channel)

    /**
     * チャンネルIDで削除
     */
    @Query("DELETE FROM channels WHERE id = :channelId")
    suspend fun deleteChannelById(channelId: String)

    /**
     * 非アクティブ化（論理削除）
     */
    @Query("UPDATE channels SET isActive = 0 WHERE id = :channelId")
    suspend fun deactivateChannel(channelId: String)

    /**
     * 施設内の全チャンネルを削除
     */
    @Query("DELETE FROM channels WHERE facilityId = :facilityId")
    suspend fun deleteChannelsByFacility(facilityId: String)

    /**
     * チャンネル数をカウント
     */
    @Query("SELECT COUNT(*) FROM channels WHERE facilityId = :facilityId AND isActive = 1")
    suspend fun getChannelCount(facilityId: String): Int

    /**
     * 緊急チャンネル数をカウント
     */
    @Query("SELECT COUNT(*) FROM channels WHERE facilityId = :facilityId AND isEmergencyChannel = 1 AND isActive = 1")
    suspend fun getEmergencyChannelCount(facilityId: String): Int

    /**
     * チャンネル検索（名前・説明文）
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId 
        AND isActive = 1 
        AND (name LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%')
        ORDER BY isEmergencyChannel DESC, name ASC
    """)
    suspend fun searchChannels(facilityId: String, query: String): List<Channel>

    /**
     * 最近更新されたチャンネルを取得
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId AND isActive = 1 
        ORDER BY updatedAt DESC 
        LIMIT :limit
    """)
    suspend fun getRecentlyUpdatedChannels(facilityId: String, limit: Int = 10): List<Channel>

    /**
     * 最近作成されたチャンネルを取得
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId AND isActive = 1 
        ORDER BY createdAt DESC 
        LIMIT :limit
    """)
    suspend fun getRecentlyCreatedChannels(facilityId: String, limit: Int = 10): List<Channel>

    /**
     * 特定の機能が有効なチャンネルを検索
     */
    @Query("""
        SELECT * FROM channels 
        WHERE facilityId = :facilityId 
        AND isActive = 1 
        AND (:allowPTT = 0 OR allowPTT = 1)
        AND (:allowVoIP = 0 OR allowVoIP = 1)
        ORDER BY isEmergencyChannel DESC, name ASC
    """)
    suspend fun getChannelsByFeatures(
        facilityId: String, 
        allowPTT: Boolean, 
        allowVoIP: Boolean
    ): List<Channel>

    /**
     * キャッシュをクリア
     */
    @Query("DELETE FROM channels")
    suspend fun clearAll()
}