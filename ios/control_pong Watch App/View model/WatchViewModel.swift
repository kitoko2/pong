//
//  WatchViewModel.swift
//  watch Watch App
//
//  Created by Dogbo Josias Ezechiel on 29/06/2024.
//

import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject {
    var session: WCSession
    // Variables publiées qui peuvent être utilisées dans la vue
    @Published var score: Int = 0
    @Published var isGameRunning: Bool = false
    
    // Add more cases if you have more receive method
    enum WatchReceiveMethod: String {
        case updateScore
        case gameState
    }
    
    // Add more cases if you have more sending method
    enum WatchSendMethod: String {
        case movePaddle
    }
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func sendDataMessage(for method: WatchSendMethod, data: [String: Any] = [:]) {
        sendMessage(for: method.rawValue, data: data)
    }
    
}

extension WatchViewModel: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    // Receive message From AppDelegate.swift that send from iOS devices
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let method = message["method"] as? String, let enumMethod = WatchReceiveMethod(rawValue: method) else {
                return
            }
            
            // Traiter les différents types de messages
                        switch method {
                            case "updateScore":
                                if let newScore = message["data"] as? Int {
                                    self.score = newScore
                                }
                            
                            case "gameState":
                                if let isRunning = message["data"] as? Bool {
                                    self.isGameRunning = isRunning
                                }
                            
                            default:
                                print("Méthode inconnue reçue: \(method)")
                        }
        }
    }
    
    func sendMessage(for method: String, data: [String: Any] = [:]) {
        guard session.isReachable else {
            return
        }
        let messageData: [String: Any] = ["method": method, "data": data]
        session.sendMessage(messageData, replyHandler: nil, errorHandler: nil)
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {

    }

    func sessionDidDeactivate(_ session: WCSession) {

    }
   #endif
    
}
