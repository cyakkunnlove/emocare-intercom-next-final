package com.emocare.intercom.next.di

import android.content.Context
import androidx.room.Room
import com.emocare.intercom.next.data.local.database.EmoCareDatabase
import com.emocare.intercom.next.data.local.database.dao.ChannelDao
import com.emocare.intercom.next.data.local.database.dao.CallHistoryDao
import com.emocare.intercom.next.data.local.database.dao.UserDao
import com.emocare.intercom.next.data.local.TokenManager
import com.emocare.intercom.next.data.local.EncryptedPreferencesManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * ローカルデータベース関連のDI設定
 * 
 * LINEレベルの品質実現のためのローカルストレージ最適化:
 * - Room データベースによる高速データアクセス
 * - 暗号化された設定ファイル管理
 * - セキュアなトークン管理
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideEmoCareDatabase(@ApplicationContext context: Context): EmoCareDatabase {
        return Room.databaseBuilder(
            context.applicationContext,
            EmoCareDatabase::class.java,
            "emocare_intercom_database"
        )
            .fallbackToDestructiveMigration() // 開発中のみ
            .build()
    }

    @Provides
    fun provideChannelDao(database: EmoCareDatabase): ChannelDao {
        return database.channelDao()
    }

    @Provides  
    fun provideCallHistoryDao(database: EmoCareDatabase): CallHistoryDao {
        return database.callHistoryDao()
    }

    @Provides
    fun provideUserDao(database: EmoCareDatabase): UserDao {
        return database.userDao()
    }

    @Provides
    @Singleton
    fun provideEncryptedPreferencesManager(
        @ApplicationContext context: Context
    ): EncryptedPreferencesManager {
        return EncryptedPreferencesManager(context)
    }

    @Provides
    @Singleton
    fun provideTokenManager(
        encryptedPreferencesManager: EncryptedPreferencesManager
    ): TokenManager {
        return TokenManager(encryptedPreferencesManager)
    }
}