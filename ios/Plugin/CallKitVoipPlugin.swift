import Foundation
import Capacitor
import UIKit
import CallKit
import PushKit
import WebRTCiOSSDK

/**
 *  CallKit Voip Plugin provides native PushKit functionality with Apple CallKit and WebRTC
 */
@objc(CallKitVoipPlugin)
public class CallKitVoipPlugin: CAPPlugin {
    
    private var provider: CXProvider?
    private let voipRegistry = PKPushRegistry(queue: nil)
    private var connectionIdRegistry: [UUID: CallConfig] = [:]
    private var webRTCClient = AntMediaClient() // WebRTC client
    
    private var pendingStreamId: String? // Store streamId from PushKit
    
    @objc func register(_ call: CAPPluginCall) {
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        
        let config = CXProviderConfiguration(localizedName: "Secure Call")
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        config.supportsVideo = true
        config.supportedHandleTypes = [.generic]
        
        provider = CXProvider(configuration: config)
        provider?.setDelegate(self, queue: DispatchQueue.main)
        call.resolve()
    }

    public func notifyEvent(eventName: String, uuid: UUID) {
        if let config = connectionIdRegistry[uuid] {
            notifyListeners(eventName, data: [
                "id": config.id,
                "media": config.media,
                "name": config.name,
                "duration": config.duration
            ])
            connectionIdRegistry[uuid] = nil
        }
    }

    public func incomingCall(id: String, media: String, name: String, duration: String) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: name)
        update.hasVideo = media == "video"
        update.supportsDTMF = false
        update.supportsHolding = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        
        let uuid = UUID()
        connectionIdRegistry[uuid] = .init(id: id, media: media, name: name, duration: duration)
        
        // Store streamId for WebRTC use
        pendingStreamId = id

        self.provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (_) in })
    }

    public func endCall(uuid: UUID) {
        let controller = CXCallController()
        let transaction = CXTransaction(action: CXEndCallAction(call: uuid))
        controller.request(transaction) { error in
            if let error = error {
                print("Error ending call: \(error.localizedDescription)")
            } else {
                print("Call ended successfully")
            }
        }
        webRTCClient.stop() // Stop WebRTC session
    }
}

// MARK: CallKit events handler
extension CallKitVoipPlugin: CXProviderDelegate {
    
    public func providerDidReset(_ provider: CXProvider) {}

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("User answered the call")
        notifyEvent(eventName: "callAnswered", uuid: action.callUUID)

        // Always start WebRTC with the provided streamId
        if let streamId = pendingStreamId {
            startWebRTCCall(streamId: streamId)
        } else {
            print("Error: Stream ID not available")
        }

        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("Call ended")
        notifyEvent(eventName: "callEnded", uuid: action.callUUID)
        endCall(uuid: action.callUUID)
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("Outgoing call started")
        notifyEvent(eventName: "callStarted", uuid: action.callUUID)
        action.fulfill()
    }
}

// MARK: WebRTC Integration
extension CallKitVoipPlugin {
    
    func startWebRTCCall(streamId: String) {
        webRTCClient.setOptions(url: "wss://stream.mybeehome.com/LiveApo", streamId: <#T##String#>)
        webRTCClient.setVideoEnable(enable: false)
        webRTCClient.start()
        webRTCClient.play(streamId: streamId)
        print("WebRTC Audio Call Started for Stream ID: \(streamId)")
    }
}

// MARK: PushKit events handler
extension CallKitVoipPlugin: PKPushRegistryDelegate {

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP Token: \(token)")
        notifyListeners("registration", data: ["value": token])
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("Incoming VoIP Call received")
        guard let id = payload.dictionaryPayload["id"] as? String else {
            print("Error: No streamId found in VoIP push")
            return
        }
        let media = (payload.dictionaryPayload["media"] as? String) ?? "voice"
        let name = (payload.dictionaryPayload["name"] as? String) ?? "Unknown"
        let duration = (payload.dictionaryPayload["duration"] as? String) ?? "0"
        
        print("Stream ID: \(id), Name: \(name), Media: \(media), Duration: \(duration)")
        
        self.incomingCall(id: id, media: media, name: name, duration: duration)
    }
}

extension CallKitVoipPlugin {
    struct CallConfig {
        let id: String
        let media: String
        let name: String
        let duration: String
    }
}
