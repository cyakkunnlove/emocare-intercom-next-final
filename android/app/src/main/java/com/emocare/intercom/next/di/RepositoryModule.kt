package com.emocare.intercom.next.di

import com.emocare.intercom.next.data.repository.AuthRepository
import com.emocare.intercom.next.data.repository.AuthRepositoryImpl
import com.emocare.intercom.next.data.repository.ChannelsRepository
import com.emocare.intercom.next.data.repository.ChannelsRepositoryImpl
import com.emocare.intercom.next.data.repository.CallHistoryRepository
import com.emocare.intercom.next.data.repository.CallHistoryRepositoryImpl
import com.emocare.intercom.next.data.repository.VoipRepository
import com.emocare.intercom.next.data.repository.VoipRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * リポジトリ層のDI設定
 * 
 * LINEレベルの品質実現のためのリポジトリパターン:
 * - データソースの抽象化
 * - ローカル・リモートデータの統合
 * - エラーハンドリングの一元管理
 * - オフライン対応
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        authRepositoryImpl: AuthRepositoryImpl
    ): AuthRepository

    @Binds
    @Singleton
    abstract fun bindChannelsRepository(
        channelsRepositoryImpl: ChannelsRepositoryImpl
    ): ChannelsRepository

    @Binds
    @Singleton
    abstract fun bindCallHistoryRepository(
        callHistoryRepositoryImpl: CallHistoryRepositoryImpl
    ): CallHistoryRepository

    @Binds
    @Singleton
    abstract fun bindVoipRepository(
        voipRepositoryImpl: VoipRepositoryImpl
    ): VoipRepository
}