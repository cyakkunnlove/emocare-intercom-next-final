package com.emocare.intercom.next.data.local.database.dao

import androidx.room.*
import com.emocare.intercom.next.domain.model.CallRecord
import com.emocare.intercom.next.domain.model.CallType
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * 通話履歴のデータアクセスオブジェクト
 * 
 * LINEレベルの品質実現のための最適化:
 * - 効率的な時系列データクエリ
 * - 統計情報の高速集計
 * - 適切なインデックス設定による高速検索
 */
@Dao
interface CallHistoryDao {

    /**
     * 全通話履歴を監視（最新順）
     */
    @Query("SELECT * FROM call_records ORDER BY startTime DESC")
    fun observeAllCallRecords(): Flow<List<CallRecord>>

    /**
     * ユーザーの通話履歴を監視
     */
    @Query("SELECT * FROM call_records WHERE callerId = :userId ORDER BY startTime DESC LIMIT :limit")
    fun observeCallRecordsByUser(userId: String, limit: Int = 100): Flow<List<CallRecord>>

    /**
     * チャンネルの通話履歴を監視
     */
    @Query("SELECT * FROM call_records WHERE channelId = :channelId ORDER BY startTime DESC LIMIT :limit")
    fun observeCallRecordsByChannel(channelId: String, limit: Int = 100): Flow<List<CallRecord>>

    /**
     * 緊急通話履歴を監視
     */
    @Query("SELECT * FROM call_records WHERE isEmergency = 1 ORDER BY startTime DESC")
    fun observeEmergencyCallRecords(): Flow<List<CallRecord>>

    /**
     * アクティブな通話を監視
     */
    @Query("SELECT * FROM call_records WHERE endTime IS NULL AND isSuccessful = 1 ORDER BY startTime DESC")
    fun observeActiveCallRecords(): Flow<List<CallRecord>>

    /**
     * 特定の通話記録を取得
     */
    @Query("SELECT * FROM call_records WHERE id = :callId")
    suspend fun getCallRecordById(callId: String): CallRecord?

    /**
     * 期間内の通話記録を取得
     */
    @Query("""
        SELECT * FROM call_records 
        WHERE startTime BETWEEN :startDate AND :endDate 
        ORDER BY startTime DESC
    """)
    suspend fun getCallRecordsByDateRange(
        startDate: LocalDateTime, 
        endDate: LocalDateTime
    ): List<CallRecord>

    /**
     * 今日の通話記録を取得
     */
    @Query("""
        SELECT * FROM call_records 
        WHERE DATE(startTime) = DATE('now', 'localtime')
        ORDER BY startTime DESC
    """)
    suspend fun getTodayCallRecords(): List<CallRecord>

    /**
     * 今週の通話記録を取得
     */
    @Query("""
        SELECT * FROM call_records 
        WHERE startTime >= DATE('now', 'localtime', 'weekday 0', '-6 days')
        ORDER BY startTime DESC
    """)
    suspend fun getThisWeekCallRecords(): List<CallRecord>

    /**
     * 今月の通話記録を取得
     */
    @Query("""
        SELECT * FROM call_records 
        WHERE startTime >= DATE('now', 'localtime', 'start of month')
        ORDER BY startTime DESC
    """)
    suspend fun getThisMonthCallRecords(): List<CallRecord>

    /**
     * 通話タイプ別の記録を取得
     */
    @Query("SELECT * FROM call_records WHERE callType = :callType ORDER BY startTime DESC LIMIT :limit")
    suspend fun getCallRecordsByType(callType: CallType, limit: Int = 100): List<CallRecord>

    /**
     * 通話記録を挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCallRecord(callRecord: CallRecord)

    /**
     * 複数の通話記録を挿入
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCallRecords(callRecords: List<CallRecord>)

    /**
     * 通話記録を更新
     */
    @Update
    suspend fun updateCallRecord(callRecord: CallRecord)

    /**
     * 通話を終了（endTime設定）
     */
    @Query("UPDATE call_records SET endTime = :endTime WHERE id = :callId")
    suspend fun endCall(callId: String, endTime: LocalDateTime)

    /**
     * 通話記録を削除
     */
    @Delete
    suspend fun deleteCallRecord(callRecord: CallRecord)

    /**
     * 通話記録IDで削除
     */
    @Query("DELETE FROM call_records WHERE id = :callId")
    suspend fun deleteCallRecordById(callId: String)

    /**
     * 古い通話記録を削除（指定日数より前）
     */
    @Query("DELETE FROM call_records WHERE startTime < :cutoffDate")
    suspend fun deleteOldCallRecords(cutoffDate: LocalDateTime)

    /**
     * 総通話数をカウント
     */
    @Query("SELECT COUNT(*) FROM call_records")
    suspend fun getTotalCallCount(): Int

    /**
     * 今日の通話数をカウント
     */
    @Query("""
        SELECT COUNT(*) FROM call_records 
        WHERE DATE(startTime) = DATE('now', 'localtime')
    """)
    suspend fun getTodayCallCount(): Int

    /**
     * 今週の通話数をカウント
     */
    @Query("""
        SELECT COUNT(*) FROM call_records 
        WHERE startTime >= DATE('now', 'localtime', 'weekday 0', '-6 days')
    """)
    suspend fun getThisWeekCallCount(): Int

    /**
     * 緊急通話数をカウント
     */
    @Query("SELECT COUNT(*) FROM call_records WHERE isEmergency = 1")
    suspend fun getEmergencyCallCount(): Int

    /**
     * 成功通話数をカウント
     */
    @Query("SELECT COUNT(*) FROM call_records WHERE isSuccessful = 1 AND endTime IS NOT NULL")
    suspend fun getSuccessfulCallCount(): Int

    /**
     * 平均通話時間を計算（完了した通話のみ）
     */
    @Query("""
        SELECT AVG(
            CASE 
                WHEN endTime IS NOT NULL 
                THEN (julianday(endTime) - julianday(startTime)) * 24 * 60 * 60
                ELSE NULL 
            END
        ) FROM call_records 
        WHERE isSuccessful = 1
    """)
    suspend fun getAverageCallDurationSeconds(): Double?

    /**
     * 最も活発なチャンネルを取得
     */
    @Query("""
        SELECT channelId
        FROM call_records 
        WHERE startTime >= DATE('now', 'localtime', '-7 days')
        GROUP BY channelId 
        ORDER BY COUNT(*) DESC 
        LIMIT 1
    """)
    suspend fun getMostActiveChannelThisWeek(): String?

    /**
     * 時間別通話数統計
     */
    @Query("""
        SELECT strftime('%H', startTime) as hour, COUNT(*) as call_count
        FROM call_records 
        WHERE startTime >= DATE('now', 'localtime', '-30 days')
        GROUP BY hour 
        ORDER BY call_count DESC
    """)
    suspend fun getCallsByHourStatistics(): List<HourlyCallStat>

    /**
     * チャンネル別通話統計
     */
    @Query("""
        SELECT channelId, COUNT(*) as call_count,
               AVG(CASE WHEN endTime IS NOT NULL 
                   THEN (julianday(endTime) - julianday(startTime)) * 24 * 60 * 60
                   ELSE NULL END) as avg_duration_seconds
        FROM call_records 
        WHERE startTime >= :since
        GROUP BY channelId
        ORDER BY call_count DESC
    """)
    suspend fun getChannelCallStatistics(since: LocalDateTime): List<ChannelCallStat>

    /**
     * 検索（発信者名・チャンネル）
     */
    @Query("""
        SELECT * FROM call_records 
        WHERE callerName LIKE '%' || :query || '%' 
        OR channelId LIKE '%' || :query || '%'
        ORDER BY startTime DESC 
        LIMIT :limit
    """)
    suspend fun searchCallRecords(query: String, limit: Int = 100): List<CallRecord>

    /**
     * キャッシュをクリア
     */
    @Query("DELETE FROM call_records")
    suspend fun clearAll()
}

/**
 * 時間別統計データクラス
 */
data class HourlyCallStat(
    val hour: String,
    val callCount: Int
)

/**
 * チャンネル別統計データクラス
 */
data class ChannelCallStat(
    val channelId: String,
    val callCount: Int,
    val avgDurationSeconds: Double?
)