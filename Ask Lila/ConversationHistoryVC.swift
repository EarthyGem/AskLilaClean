//
//  ConversationHistoryVC.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/1/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

class ConversationHistoryViewController: UITableViewController {
    var conversations: [(id: String, metadata: [String: Any])] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Conversations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        fetchConversations()
    }
    
    private func fetchConversations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("conversations")
            .order(by: "startedAt", descending: true)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Failed to fetch conversations: \(error)")
                    return
                }
                
                self.conversations = snapshot?.documents.compactMap {
                    ($0.documentID, $0.data())
                } ?? []
                self.tableView.reloadData()
            }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (id, metadata) = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let chart = metadata["chartName"] as? String ?? "Unknown Chart"
        let type = metadata["readingType"] as? String ?? "Unknown Type"
        let date = (metadata["startedAt"] as? Timestamp)?.dateValue()
        
        let dateString = date.map {
            DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short)
        } ?? "Unknown Date"
        
        cell.textLabel?.text = "🔮 \(type) — \(chart) (\(dateString))"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (conversationId, _) = conversations[indexPath.row]
        let detailVC = ConversationDetailViewController(conversationId: conversationId)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
class ConversationDetailViewController: UITableViewController {
    private let conversationId: String
    private var messages: [[String: Any]] = []
    
    init(conversationId: String) {
        self.conversationId = conversationId
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Conversation"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
        fetchMessages()
    }

    private func fetchMessages() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages").order(by: "timestamp")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Failed to fetch messages: \(error)")
                    return
                }
                self.messages = snapshot?.documents.map { $0.data() } ?? []
                self.tableView.reloadData()
            }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        let isUser = msg["isUser"] as? Bool ?? false
        let text = msg["text"] as? String ?? ""

        cell.textLabel?.text = isUser ? "🧍‍♀️ You: \(text)" : "🔮 Lila: \(text)"
        cell.textLabel?.numberOfLines = 0
        cell.backgroundColor = isUser ? UIColor.systemBlue.withAlphaComponent(0.1) : UIColor.systemGray6
        return cell
    }
}
