package com.emocare.intercom.next.data.local.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.emocare.intercom.next.data.local.database.dao.UserDao
import com.emocare.intercom.next.data.local.database.dao.ChannelDao
import com.emocare.intercom.next.data.local.database.dao.CallHistoryDao
import com.emocare.intercom.next.domain.model.User
import com.emocare.intercom.next.domain.model.Channel
import com.emocare.intercom.next.domain.model.CallRecord

/**
 * EmoCare Intercom Next Database
 * 
 * LINEレベルの品質実現のためのRoom Database設計:
 * - 効率的なインデックス設定
 * - 適切な関係性定義
 * - パフォーマンス最適化
 * - データ整合性保証
 */
@Database(
    entities = [
        User::class,
        Channel::class,
        CallRecord::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class EmoCareDatabase : RoomDatabase() {
    
    abstract fun userDao(): UserDao
    abstract fun channelDao(): ChannelDao
    abstract fun callHistoryDao(): CallHistoryDao

    companion object {
        const val DATABASE_NAME = "emocare_intercom_database"

        @Volatile
        private var INSTANCE: EmoCareDatabase? = null

        fun getDatabase(context: Context): EmoCareDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    EmoCareDatabase::class.java,
                    DATABASE_NAME
                )
                    .addMigrations() // 将来のマイグレーション対応
                    .fallbackToDestructiveMigration() // 開発中のみ
                    .build()
                INSTANCE = instance
                instance
            }
        }

        /**
         * テスト用のメモリ内データベース
         */
        fun getInMemoryDatabase(context: Context): EmoCareDatabase {
            return Room.inMemoryDatabaseBuilder(
                context.applicationContext,
                EmoCareDatabase::class.java
            )
                .allowMainThreadQueries() // テスト用のみ
                .build()
        }

        /**
         * データベースインスタンスをクリア
         */
        fun clearInstance() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}

/**
 * Room用のTypeConverter
 * LocalDateTimeやEnum等のカスタム型をデータベースで扱うための変換器
 */
class Converters {
    
    @androidx.room.TypeConverter
    fun fromTimestamp(value: Long?): java.time.LocalDateTime? {
        return value?.let { java.time.LocalDateTime.ofEpochSecond(it / 1000, (it % 1000 * 1000000).toInt(), java.time.ZoneOffset.UTC) }
    }

    @androidx.room.TypeConverter
    fun dateToTimestamp(date: java.time.LocalDateTime?): Long? {
        return date?.toEpochSecond(java.time.ZoneOffset.UTC)?.times(1000)
    }

    @androidx.room.TypeConverter
    fun fromUserRole(role: com.emocare.intercom.next.domain.model.UserRole): String {
        return role.name
    }

    @androidx.room.TypeConverter
    fun toUserRole(role: String): com.emocare.intercom.next.domain.model.UserRole {
        return com.emocare.intercom.next.domain.model.UserRole.fromString(role)
    }

    @androidx.room.TypeConverter
    fun fromCallType(type: com.emocare.intercom.next.domain.model.CallType): String {
        return type.name
    }

    @androidx.room.TypeConverter
    fun toCallType(type: String): com.emocare.intercom.next.domain.model.CallType {
        return com.emocare.intercom.next.domain.model.CallType.fromString(type)
    }

    @androidx.room.TypeConverter
    fun fromConnectionQuality(quality: com.emocare.intercom.next.domain.model.ConnectionQuality): String {
        return quality.name
    }

    @androidx.room.TypeConverter
    fun toConnectionQuality(quality: String): com.emocare.intercom.next.domain.model.ConnectionQuality {
        return try {
            com.emocare.intercom.next.domain.model.ConnectionQuality.valueOf(quality)
        } catch (e: IllegalArgumentException) {
            com.emocare.intercom.next.domain.model.ConnectionQuality.GOOD
        }
    }
}