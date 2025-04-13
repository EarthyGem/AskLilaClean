//
//  ConversationType.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/12/25.
//


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

enum ConversationType {
    case firebase
    case local
}

struct Conversation {
    var id: String
    var metadata: [String: Any]
    var type: ConversationType
}

class ConversationHistoryViewController: UITableViewController {
    var conversations: [Conversation] = []

    // Add this to the viewDidLoad method in ConversationHistoryViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Conversations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Add a refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)

        // Add Clear All button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAllButtonTapped)
        )
    }

    // Improved clearAllConversations method that properly clears Firebase conversations
    private func clearAllConversations() {
        // First clear local
        UserDefaults.standard.removeObject(forKey: "saved_conversations")

        // Then clear Firebase if logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            // If somehow not logged in, just clear local and return
            clearAllLocalConversations()
            return
        }

        let db = Firestore.firestore()
        let conversationsRef = db.collection("users").document(userId).collection("conversations")

        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: "Clearing Conversations",
            message: "Please wait while we clear your conversations...",
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)

        // Get all conversation IDs
        conversationsRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let snapshot = snapshot else {
                self?.dismiss(animated: true) {
                    self?.showErrorAlert(message: error?.localizedDescription ?? "Unknown error")
                }
                return
            }

            // If no documents, just finish
            if snapshot.documents.isEmpty {
                self.dismiss(animated: true) {
                    self.conversations = self.conversations.filter { $0.type != .firebase }
                    self.tableView.reloadData()
                    self.showToast(message: "No conversations to clear")
                }
                return
            }

            let totalConversations = snapshot.documents.count
            var deletedCount = 0
            let group = DispatchGroup()

            for document in snapshot.documents {
                group.enter()

                // First, delete all messages in the subcollection
                let messagesRef = conversationsRef.document(document.documentID).collection("messages")
                messagesRef.getDocuments { (messagesSnapshot, messagesError) in
                    if let messagesSnapshot = messagesSnapshot, !messagesSnapshot.documents.isEmpty {
                        // Delete each message document
                        let messageBatch = db.batch()
                        for messageDoc in messagesSnapshot.documents {
                            messageBatch.deleteDocument(messagesRef.document(messageDoc.documentID))
                        }

                        // Commit the message deletion batch
                        messageBatch.commit { error in
                            if let error = error {
                                print("Error deleting messages: \(error)")
                            }

                            // Now delete the conversation document
                            conversationsRef.document(document.documentID).delete { error in
                                if error == nil {
                                    deletedCount += 1
                                }
                                group.leave()
                            }
                        }
                    } else {
                        // No messages or error getting messages, just delete the conversation
                        conversationsRef.document(document.documentID).delete { error in
                            if error == nil {
                                deletedCount += 1
                            }
                            group.leave()
                        }
                    }
                }
            }

            // When all operations complete
            group.notify(queue: .main) {
                self.dismiss(animated: true) {
                    // Update UI
                    self.conversations = self.conversations.filter { $0.type != .firebase }
                    self.tableView.reloadData()

                    // Clear the first sentence cache
                    self.firstSentenceCache.removeAll()

                    // Show success message
                    self.showToast(message: "Cleared \(deletedCount) of \(totalConversations) conversations")
                }
            }
        }
    }

    // Add a toggle button for visibility too, which can be more useful than full deletion
    @objc private func clearAllButtonTapped() {
        // Count local conversations
        let localCount = conversations.filter { $0.type == .local }.count
        let firebaseCount = conversations.filter { $0.type == .firebase }.count

        let alert = UIAlertController(
            title: "Conversation Management",
            message: "Local conversations: \(localCount)\n conversations: \(firebaseCount)",
            preferredStyle: .actionSheet
        )

        // Add cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Add clear options based on what's available
        if localCount > 0 {
            alert.addAction(UIAlertAction(title: "Clear Local Only", style: .destructive) { [weak self] _ in
                self?.clearAllLocalConversations()
            })
        }

        if firebaseCount > 0 {
            // Option to hide Firebase conversations rather than delete
            alert.addAction(UIAlertAction(title: "Hide Conversations", style: .default) { [weak self] _ in
                self?.hideFirebaseConversations()
            })

            // Option to actually delete Firebase conversations
            alert.addAction(UIAlertAction(title: "Delete Conversations", style: .destructive) { [weak self] _ in
                // Show confirmation for this destructive action
                let confirmAlert = UIAlertController(
                    title: "Confirm Deletion",
                    message: "Are you sure you want to permanently delete \(firebaseCount) conversations? This cannot be undone.",
                    preferredStyle: .alert
                )

                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                    self?.clearAllConversations()
                })

                self?.present(confirmAlert, animated: true)
            })
        }

        // Option to clear all if both types exist
        if localCount > 0 && firebaseCount > 0 {
            alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
                // Show confirmation for this major destructive action
                let confirmAlert = UIAlertController(
                    title: "Confirm Deletion",
                    message: "Are you sure you want to permanently delete ALL \(localCount + firebaseCount) conversations? This cannot be undone.",
                    preferredStyle: .alert
                )

                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                confirmAlert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
                    self?.clearAllConversations()
                })

                self?.present(confirmAlert, animated: true)
            })
        }

        present(alert, animated: true)
    }

    // Method to hide Firebase conversations without deleting them
    private func hideFirebaseConversations() {
        // Just filter out Firebase conversations from the current view
        conversations = conversations.filter { $0.type != .firebase }
        tableView.reloadData()

        // Set a flag in UserDefaults to remember this preference
        UserDefaults.standard.set(true, forKey: "hideConversations")

        showToast(message: "conversations hidden")
    }

    private func clearAllLocalConversations() {
        // Remove all local conversations from UserDefaults
        UserDefaults.standard.removeObject(forKey: "saved_conversations")

        // Remove local conversations from the data source
        conversations = conversations.filter { $0.type != .local }

        // Refresh the table view
        tableView.reloadData()

        // Show confirmation toast
        showToast(message: "All local conversations cleared")
    }

    private func showToast(message: String) {
        let banner = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        banner.backgroundColor = UIColor.systemGreen
        banner.alpha = 0

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: banner.topAnchor),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor)
        ])

        view.addSubview(banner)

        UIView.animate(withDuration: 0.5, animations: {
            banner.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
                banner.alpha = 0
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }



    private func fetchFirebaseConversations() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // No logged in user, just load local conversations
            self.tableView.reloadData()
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("conversations")
            .order(by: "startedAt", descending: true)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Failed to fetch conversations: \(error)")
                    return
                }

                // Create a dispatch group to wait for all checks to complete
                let group = DispatchGroup()
                var validConversations: [Conversation] = []

                // Process each conversation
                for doc in snapshot?.documents ?? [] {
                    group.enter()

                    // Check if this conversation has at least one non-empty message
                    self.checkForNonEmptyMessages(conversationId: doc.documentID, userId: userId) { hasNonEmptyMessages in
                        if hasNonEmptyMessages {
                            // Only add conversations with actual content
                            let conversation = Conversation(
                                id: doc.documentID,
                                metadata: doc.data(),
                                type: .firebase
                            )
                            validConversations.append(conversation)
                        } else {
                            print("Skipping empty conversation: \(doc.documentID)")
                        }
                        group.leave()
                    }
                }

                // When all checks are complete, update the UI
                group.notify(queue: .main) {
                    self.conversations.append(contentsOf: validConversations)
                    self.sortConversations()
                    self.tableView.reloadData()
                }
            }
    }

    // Helper method to check if a conversation has at least one non-empty message
    private func checkForNonEmptyMessages(conversationId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error checking messages: \(error)")
                    completion(false)
                    return
                }

                // Check if there's at least one message with non-empty text
                let hasNonEmptyMessage = (snapshot?.documents ?? []).contains { doc in
                    if let text = doc.data()["text"] as? String {
                        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                    return false
                }

                completion(hasNonEmptyMessage)
            }
    }
    private func fetchLocalConversations() {
        guard let savedConversations = UserDefaults.standard.array(forKey: "saved_conversations") as? [[String: Any]] else {
            return
        }

        let localConversations = savedConversations.compactMap { dict -> Conversation? in
            guard let id = dict["id"] as? String else { return nil }

            return Conversation(
                id: id,
                metadata: dict,
                type: .local
            )
        }

        // Add local conversations
        self.conversations.append(contentsOf: localConversations)

        // Sort all conversations
        sortConversations()

        self.tableView.reloadData()
    }

    private func sortConversations() {
        conversations.sort { (a, b) -> Bool in
            let dateA = a.type == .firebase
                ? (a.metadata["startedAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
                : (a.metadata["date"] as? Date) ?? Date.distantPast

            let dateB = b.type == .firebase
                ? (b.metadata["startedAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
                : (b.metadata["date"] as? Date) ?? Date.distantPast

            return dateA > dateB // Sort descending (newest first)
        }
    }

    // MARK: - Table View Data Source & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    // Add this property to your ConversationHistoryViewController class
    private var firstSentenceCache: [String: String] = [:]

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 2 // Allow two lines for longer first sentences

        switch conversation.type {
        case .firebase:
            let date = (conversation.metadata["startedAt"] as? Timestamp)?.dateValue()
            let dateString = date.map {
                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short)
            } ?? "Unknown Date"

            // Default display (fallback)
            let readingType = conversation.metadata["readingType"] as? String ?? "Unknown Type"
            let chartName = conversation.metadata["chartName"] as? String ?? ""

            // Check if we already have this sentence cached
            if let cachedSentence = firstSentenceCache[conversation.id] {
                cell.textLabel?.text = "🔮 \"\(cachedSentence)\" (\(dateString))"
            } else {
                // Initial text while waiting for the query to load
                cell.textLabel?.text = "🔮 \(readingType) \(chartName.isEmpty ? "" : "— \(chartName)") (\(dateString))"

                // Try to fetch the first message to display its content
                fetchFirstUserMessage(conversationId: conversation.id) { [weak self] firstSentence in
                    if let firstSentence = firstSentence {
                        // Cache the result
                        self?.firstSentenceCache[conversation.id] = firstSentence

                        // Update the cell on the main thread
                        DispatchQueue.main.async {
                            if let cell = tableView.cellForRow(at: indexPath) {
                                cell.textLabel?.text = "🔮 \"\(firstSentence)\" (\(dateString))"
                            }
                        }
                    }
                }
            }

        case .local:
            let date = conversation.metadata["date"] as? Date ?? Date()
            let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)

            // Get first sentence of user query from the messages array
            var displayTitle = "Soul Chat"

            if let messages = conversation.metadata["messages"] as? [[String: Any]] {
                // Find first user message
                if let firstUserMessage = messages.first(where: { ($0["isUser"] as? Bool) == true }) {
                    if let text = firstUserMessage["text"] as? String {
                        // Extract first sentence
                        let sentenceDelimiters = CharacterSet(charactersIn: ".!?")
                        let sentences = text.components(separatedBy: sentenceDelimiters)

                        if let firstSentence = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines), !firstSentence.isEmpty {
                            // Truncate if needed
                            let maxLength = 50
                            displayTitle = firstSentence.count > maxLength ?
                                "\(firstSentence.prefix(maxLength))..." : firstSentence
                        }
                    }
                }
            } else if let title = conversation.metadata["title"] as? String {
                // Fallback to title if no messages array
                let maxLength = 50
                displayTitle = title.count > maxLength ?
                    "\(title.prefix(maxLength))..." : title
            }

            cell.textLabel?.text = "💬 \"\(displayTitle)\" (\(dateString))"
        }

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Add this method to clear the cache when refreshing data
    @objc private func refreshData() {
        // Clear the first sentence cache when refreshing
        firstSentenceCache.removeAll()

        conversations = []

        // Load both types of data
        fetchFirebaseConversations()
        fetchLocalConversations()

        // If we're refreshing from pull to refresh, end it after 1 second
        if refreshControl?.isRefreshing == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    // Optimized helper method to fetch the first user message for Firebase conversations
    private func fetchFirstUserMessage(conversationId: String, completion: @escaping (String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        let db = Firestore.firestore()

        // Query the messages subcollection, filtering for user messages and ordering by timestamp
        db.collection("users").document(userId)
            .collection("conversations").document(conversationId)
            .collection("messages")
            .whereField("isUser", isEqualTo: true)
            .order(by: "timestamp")
            .limit(to: 1)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching message: \(error)")
                    completion(nil)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(nil)
                    return
                }

                // Get the first message's text
                if let text = documents[0].data()["text"] as? String {
                    // Extract first sentence
                    let sentenceDelimiters = CharacterSet(charactersIn: ".!?")
                    let sentences = text.components(separatedBy: sentenceDelimiters)

                    if let firstSentence = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines), !firstSentence.isEmpty {
                        // Truncate if needed
                        let maxLength = 50
                        let displayTitle = firstSentence.count > maxLength ?
                            "\(firstSentence.prefix(maxLength))..." : firstSentence

                        completion(displayTitle)
                        return
                    }
                }

                completion(nil)
            }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]

        switch conversation.type {
        case .firebase:
            let detailVC = FirebaseConversationDetailVC(conversationId: conversation.id)
            navigationController?.pushViewController(detailVC, animated: true)

        case .local:
            if let messages = conversation.metadata["messages"] as? [[String: Any]] {
                let detailVC = LocalConversationDetailVC(messages: messages)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversation = conversations[indexPath.row]

            switch conversation.type {
            case .firebase:
                deleteFirebaseConversation(at: indexPath)

            case .local:
                deleteLocalConversation(at: indexPath)
            }
        }
    }

    private func deleteFirebaseConversation(at indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("conversations").document(conversation.id)
            .delete { [weak self] error in
                if let error = error {
                    print("Error deleting document: \(error)")
                } else {
                    guard let self = self else { return }
                    self.conversations.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
    }

    private func deleteLocalConversation(at indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]

        // Get saved conversations from UserDefaults
        guard var savedConversations = UserDefaults.standard.array(forKey: "saved_conversations") as? [[String: Any]] else {
            return
        }

        // Find and remove the conversation with matching ID
        if let index = savedConversations.firstIndex(where: { ($0["id"] as? String) == conversation.id }) {
            savedConversations.remove(at: index)

            // Save back to UserDefaults
            UserDefaults.standard.set(savedConversations, forKey: "saved_conversations")

            // Update UI
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - Firebase Detail View Controller

// MARK: - Local Detail View Controller
class LocalConversationDetailVC: UITableViewController {
    private var messages: [[String: Any]]
    private var conversationTitle: String

    init(messages: [[String: Any]], title: String? = nil) {
        self.messages = messages

        // Filter out any empty messages
        self.messages = messages.filter { message in
            guard let text = message["text"] as? String else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        self.conversationTitle = title ?? "Soul Chat"
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = conversationTitle
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")

        // Add a share button to the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareConversation)
        )
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

    @objc private func shareConversation() {
        // Create a text representation of the conversation
        var conversationText = "Conversation with Lila\n\n"

        for message in messages {
            let isUser = message["isUser"] as? Bool ?? false
            let text = message["text"] as? String ?? ""

            let prefix = isUser ? "You: " : "Lila: "
            conversationText += "\(prefix)\(text)\n\n"
        }

        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [conversationText],
            applicationActivities: nil
        )

        // Present the view controller
        present(activityVC, animated: true)
    }
}
class FirebaseConversationDetailVC: UITableViewController {
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
