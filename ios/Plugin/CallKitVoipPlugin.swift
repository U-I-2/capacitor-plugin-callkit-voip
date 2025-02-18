import Foundation
import Capacitor
import UIKit
import CallKit
import PushKit

/**
 *  CallKit Voip Plugin provides native PushKit functionality with apple CallKit to capacitor
 */
@objc(CallKitVoipPlugin)
public class CallKitVoipPlugin: CAPPlugin {

    private var provider: CXProvider?
    private let voipRegistry            = PKPushRegistry(queue: nil)
    private var connectionIdRegistry : [UUID: CallConfig] = [:]
  var pendingCallUUID: UUID?

    @objc func register(_ call: CAPPluginCall) {
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        let config = CXProviderConfiguration(localizedName: "Secure Call")
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        // Native call log shows video icon if it was video call.
        config.supportsVideo = true
        // Support generic type to handle *User ID*
        config.supportedHandleTypes = [.generic]
        provider = CXProvider(configuration: config)
        provider?.setDelegate(self, queue: DispatchQueue.main)
        call.resolve()
    }

    public func notifyEvent(eventName: String, uuid: UUID){
        if let config = connectionIdRegistry[uuid] {
            notifyListeners(eventName, data: [
                "id": config.id,
                "media": config.media,
                "name"    : config.name,
                "duration"    : config.duration,
            ])
            connectionIdRegistry[uuid] = nil
        }
    }

    public func incomingCall(id: String, media: String, name: String, duration: String) {
        let update                      = CXCallUpdate()
        update.remoteHandle             = CXHandle(type: .generic, value: name)
        update.hasVideo                 = media == "video"
        update.supportsDTMF             = false
        update.supportsHolding          = true
        update.supportsGrouping         = false
        update.supportsUngrouping       = false
        let uuid = UUID()
        connectionIdRegistry[uuid] = .init(id: id, media: media, name: name, duration: duration)
        self.provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (_) in })
    }




    public func endCall(uuid: UUID) {
        let controller = CXCallController()
        let transaction = CXTransaction(action: CXEndCallAction(call: uuid));controller.request(transaction,completion: { error in })
    }



}


// MARK: CallKit events handler

extension CallKitVoipPlugin: CXProviderDelegate {

    public func providerDidReset(_ provider: CXProvider) {

    }
 
  public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
      print("User answered the call")
      notifyEvent(eventName: "callAnswered", uuid: action.callUUID)
      
      if UIApplication.shared.applicationState != .active {
          // Save the UUID for later use
          pendingCallUUID = action.callUUID
          // Add observer for when the app becomes active
          NotificationCenter.default.addObserver(self,
                                                 selector: #selector(appDidBecomeActive),
                                                 name: UIApplication.didBecomeActiveNotification,
                                                 object: nil)
      } else {
          // If already active, end the call after a delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
              self.endCall(uuid: action.callUUID)
          }
      }
      
      action.fulfill()
  }
  @objc func appDidBecomeActive(_ notification: Notification) {
      if let uuid = pendingCallUUID {
          self.endCall(uuid: uuid)
          pendingCallUUID = nil
          NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
      }
  }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // End the call
        print("CXEndCallAction represents ending call")
        notifyEvent(eventName: "callEnded", uuid: action.callUUID)
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // Report connection started
        print("CXStartCallAction represents initiating an outgoing call")
        notifyEvent(eventName: "callStarted", uuid: action.callUUID)
        action.fulfill()
    }
  
  private func scheduleLocalNotification() {
      let content = UNMutableNotificationContent()
      content.title = "Call Started"
      content.body = "Tap to open BeeHome"
      content.userInfo = ["url": "beehome://"]
      
      // Fire the notification shortly after scheduling it
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(identifier: "BeeHomeCallNotification",
                                          content: content,
                                          trigger: trigger)
      
      UNUserNotificationCenter.current().add(request) { error in
          if let error = error {
              print("Error scheduling local notification: \(error)")
          }
      }
  }


}

// MARK: PushKit events handler
extension CallKitVoipPlugin: PKPushRegistryDelegate {

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let parts = pushCredentials.token.map { String(format: "%02.2hhx", $0) }
        let token = parts.joined()
        print("Token: \(token)")
        notifyListeners("registration", data: ["value": token])
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
         print("didReceiveIncomingPushWith")
         guard let id = payload.dictionaryPayload["id"] as? String else {
             return
         }
         let media = (payload.dictionaryPayload["media"] as? String) ?? "voice"
         let name = (payload.dictionaryPayload["name"] as? String) ?? "Unknown"
         let duration = (payload.dictionaryPayload["duration"] as? String) ?? "0"
         print("id: \(id)")
         print("name: \(name)")
         print("media: \(media)")
         print("duration: \(duration)")
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
