package com.emocare.intercom.next.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 暗号化された設定ファイル管理クラス
 * 
 * LINEレベルの品質実現のためのセキュアストレージ:
 * - AES256暗号化による設定値保護
 * - Android Keystore統合
 * - セキュアなキー管理
 * - 効率的な読み書き操作
 */
@Singleton
class EncryptedPreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val SHARED_PREFS_FILENAME = "emocare_intercom_encrypted_prefs"
    }

    private val sharedPreferences: SharedPreferences by lazy {
        createEncryptedSharedPreferences()
    }

    /**
     * 文字列値を保存
     */
    suspend fun saveString(key: String, value: String) {
        sharedPreferences.edit()
            .putString(key, value)
            .apply()
    }

    /**
     * 文字列値を取得
     */
    suspend fun getString(key: String): String? {
        return sharedPreferences.getString(key, null)
    }

    /**
     * 整数値を保存
     */
    suspend fun saveInt(key: String, value: Int) {
        sharedPreferences.edit()
            .putInt(key, value)
            .apply()
    }

    /**
     * 整数値を取得
     */
    suspend fun getInt(key: String, defaultValue: Int = 0): Int {
        return sharedPreferences.getInt(key, defaultValue)
    }

    /**
     * 真偽値を保存
     */
    suspend fun saveBoolean(key: String, value: Boolean) {
        sharedPreferences.edit()
            .putBoolean(key, value)
            .apply()
    }

    /**
     * 真偽値を取得
     */
    suspend fun getBoolean(key: String, defaultValue: Boolean = false): Boolean {
        return sharedPreferences.getBoolean(key, defaultValue)
    }

    /**
     * 浮動小数点値を保存
     */
    suspend fun saveFloat(key: String, value: Float) {
        sharedPreferences.edit()
            .putFloat(key, value)
            .apply()
    }

    /**
     * 浮動小数点値を取得
     */
    suspend fun getFloat(key: String, defaultValue: Float = 0f): Float {
        return sharedPreferences.getFloat(key, defaultValue)
    }

    /**
     * 長整数値を保存
     */
    suspend fun saveLong(key: String, value: Long) {
        sharedPreferences.edit()
            .putLong(key, value)
            .apply()
    }

    /**
     * 長整数値を取得
     */
    suspend fun getLong(key: String, defaultValue: Long = 0L): Long {
        return sharedPreferences.getLong(key, defaultValue)
    }

    /**
     * 文字列セットを保存
     */
    suspend fun saveStringSet(key: String, values: Set<String>) {
        sharedPreferences.edit()
            .putStringSet(key, values)
            .apply()
    }

    /**
     * 文字列セットを取得
     */
    suspend fun getStringSet(key: String): Set<String>? {
        return sharedPreferences.getStringSet(key, null)
    }

    /**
     * キーが存在するかチェック
     */
    suspend fun hasKey(key: String): Boolean {
        return sharedPreferences.contains(key)
    }

    /**
     * キーを削除
     */
    suspend fun removeKey(key: String) {
        sharedPreferences.edit()
            .remove(key)
            .apply()
    }

    /**
     * 全ての値をクリア
     */
    suspend fun clearAll() {
        sharedPreferences.edit()
            .clear()
            .apply()
    }

    /**
     * 保存されている全キーを取得
     */
    suspend fun getAllKeys(): Set<String> {
        return sharedPreferences.all.keys
    }

    /**
     * JSON文字列として複合オブジェクトを保存
     */
    suspend fun saveJson(key: String, jsonString: String) {
        saveString(key, jsonString)
    }

    /**
     * JSON文字列として複合オブジェクトを取得
     */
    suspend fun getJson(key: String): String? {
        return getString(key)
    }

    /**
     * 設定のバックアップを作成
     */
    suspend fun createBackup(): Map<String, Any?> {
        return sharedPreferences.all.toMap()
    }

    /**
     * バックアップから設定を復元
     */
    suspend fun restoreFromBackup(backup: Map<String, Any?>) {
        val editor = sharedPreferences.edit()
        
        backup.forEach { (key, value) ->
            when (value) {
                is String -> editor.putString(key, value)
                is Int -> editor.putInt(key, value)
                is Boolean -> editor.putBoolean(key, value)
                is Float -> editor.putFloat(key, value)
                is Long -> editor.putLong(key, value)
                is Set<*> -> {
                    @Suppress("UNCHECKED_CAST")
                    editor.putStringSet(key, value as Set<String>)
                }
            }
        }
        
        editor.apply()
    }

    /**
     * 暗号化されたSharedPreferencesを作成
     */
    private fun createEncryptedSharedPreferences(): SharedPreferences {
        return try {
            val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            
            EncryptedSharedPreferences.create(
                SHARED_PREFS_FILENAME,
                masterKeyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // フォールバック: 暗号化に失敗した場合は通常のSharedPreferences
            // 本番環境では適切なエラーハンドリングが必要
            android.util.Log.e("EncryptedPreferencesManager", "Failed to create encrypted preferences", e)
            
            context.getSharedPreferences(
                "${SHARED_PREFS_FILENAME}_fallback",
                Context.MODE_PRIVATE
            )
        }
    }

    /**
     * デバッグ情報取得（開発時のみ）
     */
    suspend fun getDebugInfo(): String {
        return if (com.emocare.intercom.next.BuildConfig.DEBUG) {
            val allKeys = getAllKeys()
            val keyCount = allKeys.size
            "EncryptedPreferences: $keyCount keys stored: ${allKeys.joinToString(", ")}"
        } else {
            "Debug info not available in release build"
        }
    }
}