package com.emocare.intercom.next.system.telecom

import android.telecom.*
import android.util.Log
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

/**
 * EmoCare VoIP通話用ConnectionService
 * 
 * LINEレベル品質実現のためのAndroid Telecom Framework統合:
 * - システムレベル通話UI統合
 * - 通話履歴システム連携
 * - バックグラウンド通話継続
 * - ネイティブ通話操作対応
 */
@AndroidEntryPoint
class EmoCareConnectionService : ConnectionService() {

    @Inject
    lateinit var callController: EmoCareCallController

    companion object {
        private const val TAG = "EmoCareConnectionSvc"
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        Log.d(TAG, "Creating incoming connection")
        
        val metadata = EmoCareCallMetadata.fromBundle(request.extras, isIncoming = true)
            ?: return Connection.createFailedConnection(
                DisconnectCause(DisconnectCause.ERROR, "Invalid incoming call metadata")
            )

        return callController.createConnection(metadata)
    }

    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ) {
        super.onCreateIncomingConnectionFailed(connectionManagerPhoneAccount, request)
        Log.w(TAG, "Failed to create incoming connection")
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        Log.d(TAG, "Creating outgoing connection")
        
        val metadata = EmoCareCallMetadata.fromBundle(request.extras, isIncoming = false)
            ?: return Connection.createFailedConnection(
                DisconnectCause(DisconnectCause.ERROR, "Invalid outgoing call metadata")
            )

        return callController.createConnection(metadata)
    }

    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ) {
        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request)
        Log.w(TAG, "Failed to create outgoing connection")
    }

    override fun onConnectionServiceFocusLost() {
        super.onConnectionServiceFocusLost()
        Log.d(TAG, "Connection service focus lost")
    }

    override fun onConnectionServiceFocusGained() {
        super.onConnectionServiceFocusGained()
        Log.d(TAG, "Connection service focus gained")
    }
}