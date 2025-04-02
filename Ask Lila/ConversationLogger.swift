//
//  ConversationLogger.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/1/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

class ConversationLogger {
    
    static let shared = ConversationLogger()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func logConversation(prompt: String,
                         response: String,
                         readingType: String,
                         chartName: String?,
                         partnerName: String? = nil,
                         transitDate: Date? = nil) {
        
        // ✅ Make sure user is logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ Cannot log conversation — no user ID")
            return
        }
        print("🔥 Attempting to log conversation...")
        print("👤 User ID: \(Auth.auth().currentUser?.uid ?? "nil")")
        print("📝 Prompt: \(prompt.prefix(50))")
        print("📝 Response: \(response.prefix(50))")
        print("🪵 ConversationLogger: starting to log conversation")

        let conversationId = UUID().uuidString
        let timestamp = Timestamp(date: Date())
        
        // ✅ Build metadata
        var metadata: [String: Any] = [
            "readingType": readingType,
            "startedAt": timestamp,
            "chartName": chartName ?? "Unnamed"
        ]
        
        if let partner = partnerName {
            metadata["partnerChartName"] = partner
        }
        
        if let date = transitDate {
            metadata["transitDate"] = Timestamp(date: date)
        }

        let userMessage: [String: Any] = [
            "text": prompt,
            "isUser": true,
            "timestamp": timestamp
        ]
        
        let aiMessage: [String: Any] = [
            "text": response,
            "isUser": false,
            "timestamp": timestamp
        ]
        
        let conversationRef = db.collection("users")
            .document(userId)
            .collection("conversations")
            .document(conversationId)
        
        // ✅ Write metadata with error handling
        conversationRef.setData(metadata) { error in
            if let error = error {
                print("❌ Failed to write conversation metadata: \(error.localizedDescription)")
                return
            }
            
            print("✅ Metadata logged for conversation: \(conversationId)")
            
            // ✅ Add user message
            conversationRef.collection("messages").addDocument(data: userMessage) { error in
                if let error = error {
                    print("❌ Failed to save user message: \(error.localizedDescription)")
                } else {
                    print("✅ Saved user message to Firestore")
                }
            }
            
            // ✅ Add AI message
            conversationRef.collection("messages").addDocument(data: aiMessage) { error in
                if let error = error {
                    print("❌ Failed to save assistant message: \(error.localizedDescription)")
                } else {
                    print("✅ Saved assistant message to Firestore")
                }
            }
        }
    }
}
