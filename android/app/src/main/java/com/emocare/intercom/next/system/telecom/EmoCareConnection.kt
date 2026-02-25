package com.emocare.intercom.next.system.telecom

import android.net.Uri
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.telecom.TelecomManager
import android.util.Log

/**
 * EmoCare VoIP Connection
 * 
 * 個別通話接続の管理:
 * - Android Telecom Framework統合
 * - 通話状態変更処理
 * - UI操作ハンドリング
 * - LiveKit音声制御
 */
class EmoCareConnection(
    private val metadata: EmoCareCallMetadata,
    private val controller: EmoCareCallController
) : Connection() {

    companion object {
        private const val TAG = "EmoCareConnection"
    }

    init {
        Log.d(TAG, "Creating connection: ${metadata.callId}")
        
        // 基本設定
        setAddress(Uri.parse("tel:${metadata.targetId}"), TelecomManager.PRESENTATION_ALLOWED)
        setCallerDisplayName(metadata.callerName, TelecomManager.PRESENTATION_ALLOWED)
        
        // 通話機能設定
        connectionCapabilities = CAPABILITY_HOLD or 
                                 CAPABILITY_SUPPORT_HOLD or
                                 CAPABILITY_MUTE
        
        // 音声設定
        audioModeIsVoip = true
    }

    override fun onAnswer() {
        Log.d(TAG, "Answer call: ${metadata.callId}")
        controller.answerCall(metadata.callId)
    }

    override fun onAnswer(videoState: Int) {
        Log.d(TAG, "Answer call with video: ${metadata.callId}, videoState: $videoState")
        controller.answerCall(metadata.callId)
    }

    override fun onReject() {
        Log.d(TAG, "Reject call: ${metadata.callId}")
        controller.rejectCall(metadata.callId)
    }

    override fun onReject(rejectReason: Int) {
        Log.d(TAG, "Reject call with reason: ${metadata.callId}, reason: $rejectReason")
        controller.rejectCall(metadata.callId)
    }

    override fun onDisconnect() {
        Log.d(TAG, "Disconnect call: ${metadata.callId}")
        controller.endCall(metadata.callId)
        destroy()
    }

    override fun onAbort() {
        Log.d(TAG, "Abort call: ${metadata.callId}")
        setDisconnected(DisconnectCause(DisconnectCause.CANCELED, "Call aborted"))
        destroy()
    }

    override fun onHold() {
        Log.d(TAG, "Hold call: ${metadata.callId}")
        controller.holdCall(metadata.callId, true)
    }

    override fun onUnhold() {
        Log.d(TAG, "Unhold call: ${metadata.callId}")
        controller.holdCall(metadata.callId, false)
    }

    override fun onMute(isMuted: Boolean) {
        Log.d(TAG, "Mute call: ${metadata.callId}, muted: $isMuted")
        controller.muteCall(metadata.callId, isMuted)
    }

    override fun onStateChanged(state: Int) {
        super.onStateChanged(state)
        Log.d(TAG, "Connection state changed: ${metadata.callId}, state: $state")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Connection destroyed: ${metadata.callId}")
        controller.onConnectionDestroyed(metadata.callId)
    }

    // State helper methods
    fun setInitializing() {
        Log.d(TAG, "Set initializing: ${metadata.callId}")
        setInitialized()
    }

    fun setDialing() {
        Log.d(TAG, "Set dialing: ${metadata.callId}")
        setDialing()
    }

    fun setRinging() {
        Log.d(TAG, "Set ringing: ${metadata.callId}")
        setRinging()
    }

    fun setActive() {
        Log.d(TAG, "Set active: ${metadata.callId}")
        setActive()
    }

    fun setOnHold(hold: Boolean) {
        Log.d(TAG, "Set hold: ${metadata.callId}, hold: $hold")
        if (hold) {
            setOnHold()
        } else {
            setActive()
        }
    }
}