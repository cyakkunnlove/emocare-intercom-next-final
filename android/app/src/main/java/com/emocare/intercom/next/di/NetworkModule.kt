package com.emocare.intercom.next.di

import com.emocare.intercom.next.data.network.SupabaseApiService
import com.emocare.intercom.next.data.network.LiveKitApiService
import com.emocare.intercom.next.data.network.ApiInterceptor
import com.emocare.intercom.next.data.local.TokenManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Qualifier
import javax.inject.Singleton

/**
 * ネットワーク関連のDI設定
 * 
 * LINEレベルの品質を実現するための最適化:
 * - 効率的なHTTPクライアント設定
 * - 適切なタイムアウト設定
 * - リクエスト/レスポンス のログ記録
 * - 認証トークンの自動管理
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Qualifier
    @Retention(AnnotationRetention.BINARY)
    annotation class SupabaseRetrofit

    @Qualifier
    @Retention(AnnotationRetention.BINARY) 
    annotation class LiveKitRetrofit

    @Provides
    @Singleton
    fun provideHttpLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = if (com.emocare.intercom.next.BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }
    }

    @Provides
    @Singleton
    fun provideApiInterceptor(tokenManager: TokenManager): ApiInterceptor {
        return ApiInterceptor(tokenManager)
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        apiInterceptor: ApiInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(apiInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
    }

    @Provides
    @Singleton
    @SupabaseRetrofit
    fun provideSupabaseRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://your-supabase-url.supabase.co/") // TODO: 実際のURLに置き換え
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    @LiveKitRetrofit
    fun provideLiveKitRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://your-livekit-server.com/") // TODO: 実際のURLに置き換え
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideSupabaseApiService(@SupabaseRetrofit retrofit: Retrofit): SupabaseApiService {
        return retrofit.create(SupabaseApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideLiveKitApiService(@LiveKitRetrofit retrofit: Retrofit): LiveKitApiService {
        return retrofit.create(LiveKitApiService::class.java)
    }
}