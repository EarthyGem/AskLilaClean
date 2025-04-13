import Foundation
import UIKit
import SwiftEphemeris

class SoulChatViewController: UIViewController {

    // MARK: - Chart + Profile Data
    var userChart: UserChartProfile!
    var soulProfile: SoulValuesProfile!
    var toneProfile: AlchemicalToneProfile!
    var relationalSignature: RelationalSignature!

    // MARK: - UI Elements
    let tableView = UITableView()
    let inputTextView = UITextView()
    let sendButton = UIButton(type: .system)

    // Add toolbar buttons
    let saveButton = UIButton(type: .system)
    let clearButton = UIButton(type: .system)
    let toolbarView = UIView()

    // Unique identifier for this conversation
    private var conversationID: String = UUID().uuidString

    var messages: [(String, Bool)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chat with Lila 🌿"
        setupKeyboardNotifications()
        setupUI()
        generateProfiles()
        let claudeService = ClaudeAstrologyService(apiKey: APIKeys.anthropic)
        AIServiceManager.shared.currentService = claudeService

        // Save this preference
        UserDefaults.standard.set(1, forKey: "selectedAIService")

        // Load saved messages if they exist
        loadMessages()

        // Only add welcome message if there are no saved messages
        if messages.isEmpty {
            addSystemMessage("✨ Hi, beautiful soul. I'm here to walk beside you. Ask me anything on your path.")
        }
    }

    private func generateProfiles() {
        let (soul, tone, relation) = buildSoulProfiles(from: userChart)
        soulProfile = soul
        toneProfile = tone
        relationalSignature = relation
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)

        // Create toolbar view
        toolbarView.backgroundColor = .systemBackground
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.layer.borderColor = UIColor.lightGray.cgColor
        toolbarView.layer.borderWidth = 0.5
        view.addSubview(toolbarView)

        // Configure save button
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveConversation), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(saveButton)

        // Configure clear button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.addTarget(self, action: #selector(clearConversation), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(clearButton)

        inputTextView.font = UIFont.systemFont(ofSize: 16)
        inputTextView.layer.cornerRadius = 8
        inputTextView.layer.borderColor = UIColor.lightGray.cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputTextView)

        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
            // Toolbar constraints
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 44),

            // Toolbar buttons
            saveButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            saveButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            // Adjust table view to start below toolbar
            tableView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -8),

            inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            inputTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.heightAnchor.constraint(equalToConstant: 40),

            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])

        // Add tap gesture recognizer to dismiss keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
            // Reset the constraint
            self.view.constraints.first(where: { $0.firstAttribute == .bottom && $0.firstItem is UIView })?.constant = 0

            self.view.layoutIfNeeded()
            self.tableView.contentInset.bottom = 0
            self.tableView.scrollIndicatorInsets.bottom = 0
        }
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardHeight = keyboardFrame.height
        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        // Calculate the bottom constraint value
        let bottomConstant = keyboardHeight - view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
            // Update the constraint to adjust for keyboard height
            // Assuming you've stored this constraint as a property - you'll need to add this
            self.view.constraints.first(where: { $0.firstAttribute == .bottom && $0.firstItem is UIView })?.constant = -bottomConstant

            self.view.layoutIfNeeded()
            self.tableView.contentInset.bottom = 0
            self.tableView.scrollIndicatorInsets.bottom = 0
            self.scrollToBottom()
        }
    }
    @objc private func sendTapped() {
        guard let text = inputTextView.text, !text.isEmpty else { return }
        messages.append((text, true))
        inputTextView.text = ""
        tableView.reloadData()
        scrollToBottom()

        // Save messages after each new message
        saveMessages()

        sendMessageToLila(userMessage: text)
    }

    private func addSystemMessage(_ text: String) {
        messages.append((text, false))
        tableView.reloadData()
        scrollToBottom()

        // Save messages after adding system message
        saveMessages()
    }

    private func scrollToBottom() {
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - Message Persistence
    private func loadMessages() {
        if let savedMessages = UserDefaults.standard.array(forKey: "chat_messages") as? [[String: Any]] {
            messages = savedMessages.compactMap { dict in
                if let text = dict["text"] as? String,
                   let isUser = dict["isUser"] as? Bool {
                    return (text, isUser)
                }
                return nil
            }

            tableView.reloadData()
            if !messages.isEmpty {
                scrollToBottom()
            }
        }
    }

    private func saveMessages() {
        let messageDicts = messages.map { (text, isUser) -> [String: Any] in
            return ["text": text, "isUser": isUser]
        }
        UserDefaults.standard.set(messageDicts, forKey: "chat_messages")
    }

    @objc private func saveConversation() {
        // Filter out any empty messages
        let filteredMessages = messages.filter { (text, _) in
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Make sure we have messages to save
        guard !filteredMessages.isEmpty else {
            let alert = UIAlertController(title: "Empty Conversation", message: "There are no messages to save.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Find first user message to use as title
        let title = filteredMessages.first(where: { $0.1 == true })?.0 ?? "Conversation with Lila"

        // Create a dictionary with conversation data
        let conversationData: [String: Any] = [
            "id": conversationID,
            "date": Date(),
            "messages": filteredMessages.map { (text, isUser) -> [String: Any] in
                return ["text": text, "isUser": isUser]
            },
            "title": title,  // Add the title for display in the table view
            "type": "SoulChat"  // Adding type to differentiate from other conversation types
        ]

        // Get existing saved conversations
        var savedConversations = UserDefaults.standard.array(forKey: "saved_conversations") as? [[String: Any]] ?? []

        // Check if conversation with this ID already exists
        if let existingIndex = savedConversations.firstIndex(where: { ($0["id"] as? String) == conversationID }) {
            // Update existing conversation
            savedConversations[existingIndex] = conversationData
        } else {
            // Add this conversation to the list
            savedConversations.append(conversationData)
        }

        // Save back to UserDefaults
        UserDefaults.standard.set(savedConversations, forKey: "saved_conversations")

        // Show confirmation alert
        let alert = UIAlertController(title: "Conversation Saved", message: "Your conversation with Lila has been saved and can be accessed from the Past Conversations screen.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @objc private func clearConversation() {
        // Show confirmation alert
        let alert = UIAlertController(title: "Clear Conversation", message: "Are you sure you want to clear this conversation?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            // Clear messages
            self.messages.removeAll()
            self.tableView.reloadData()

            // Reset UserDefaults
            UserDefaults.standard.removeObject(forKey: "chat_messages")

            // Generate new conversation ID
            self.conversationID = UUID().uuidString

            // Add welcome message
            self.addSystemMessage("✨ Hi, beautiful soul. I'm here to walk beside you. Ask me anything on your path.")
        })

        present(alert, animated: true)
    }

    private func sendMessageToLila(userMessage: String) {
        print("DEBUG: Starting to send message to Lila")

        // Check if userChart exists
        guard let userChart = userChart else {
            print("DEBUG: ERROR - userChart is nil")
            self.addSystemMessage("⚠️ Unable to process your request: Chart data is missing")
            return
        }

        print("DEBUG: Building core chart profile")
        let coreProfile = buildCoreChartProfile(from: userChart)
        print("DEBUG: Core profile created: \(coreProfile)")

        print("DEBUG: Creating filter with soul, tone, relation profiles")
        let filter = ChartReflectionFilter(
            soul: soulProfile,
            tone: toneProfile,
            relation: relationalSignature
        )

        print("DEBUG: Generating prompt")
        let fullPrompt = filter.createPrompt(with: userMessage, core: coreProfile)
        print("DEBUG: Prompt generated: \(fullPrompt.prefix(100))...")

        print("DEBUG: Checking if AI service exists")
        let aiService = AIServiceManager.shared.currentService

        print("DEBUG: Sending request to AI service")
        aiService.generateResponse(
            prompt: fullPrompt,
            chartCake: nil,
            otherChart: nil,
            transitDate: nil
        ) { [weak self] result in
            print("DEBUG: Received response from AI service")
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let reply):
                    print("DEBUG: Success - got reply of length \(reply.count)")
                    self.messages.append((reply, false))
                    self.tableView.reloadData()
                    self.scrollToBottom()

                    // Save messages after receiving reply
                    self.saveMessages()

                case .failure(let error):
                    print("DEBUG: ERROR - AI service failed: \(error.localizedDescription)")
                    self.messages.append(("⚠️ There was an issue connecting with Lila's wisdom: \(error.localizedDescription)", false))
                    self.tableView.reloadData()
                    self.scrollToBottom()

                    // Save messages even when there's an error
                    self.saveMessages()
                }
            }
        }
    }
}
// MARK: - Table View
extension SoulChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (text, isUser) = messages[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = text
        cell.textLabel?.textAlignment = isUser ? .right : .left
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        return cell
    }
}

struct ChartReflectionFilter {
    let soul: SoulValuesProfile
    let tone: AlchemicalToneProfile
    let relation: RelationalSignature

    func createPrompt(with userMessage: String, core: UserCoreChartProfile) -> String {
        return toneAdjustedResponse(
            userInput: userMessage,
            core: core,
            soul: soul,
            tone: tone
        )
    }
}

func toneAdjustedResponse(userInput: String, core: UserCoreChartProfile, soul: SoulValuesProfile, tone: AlchemicalToneProfile) -> String {
    return """
🜁 You are a soul-reflective assistant aligned with the Personal Alchemy philosophy.

Your reply should reflect the following chart truths:

• Strongest Planet: \(core.strongestPlanet.keyName) in \(core.strongestPlanetSign.rawValue), House \(core.strongestPlanetHouse)
   → Speak to refinement of \(tone.soulFunction)

• Moon: \(core.moonSign.rawValue), House \(core.moonHouse)
   → Respond in a way that nurtures: \(soul.blossomingConditions)

• Mercury: \(core.mercurySign.rawValue), House \(core.mercuryHouse)
   → Communicate in a tone of: \(soul.communicationMode)

• Sun: \(core.sunSign.rawValue), House \(core.sunHouse)
   → Honor their growth path: \(soul.radiancePath)

• Current arena of development: \(tone.developmentArena)
• Emotional tone: \(tone.preferredReception)
• Learning style: \(tone.symbolicVoiceTone ?? "Natural language rooted in chart themes")

PHILOSOPHY:
This user is not broken—they are refining. 
Speak through the lens of the 7-fold system. Honor effort over outcome. Reflect where growth is happening.

--- USER QUESTION ---
\(userInput)

--- YOUR SOUL-AWARE RESPONSE ---
"""
}
//struct ChartReflectionFilter {
//    let soul: SoulValuesProfile
//    let tone: AlchemicalToneProfile
//    let relation: RelationalSignature
//
//    func createPrompt(with userMessage: String, core: UserCoreChartProfile) -> String {
//        return toneAdjustedResponse(
//            userInput: userMessage,
//            core: core,
//            soul: soul,
//            tone: tone
//        )
//    }
//}

//func toneAdjustedResponse(userInput: String, core: UserCoreChartProfile, soul: SoulValuesProfile, tone: AlchemicalToneProfile) -> String {
//    return """
//🜁 You are a soul-reflective assistant aligned with the Personal Alchemy philosophy.
//
//Your reply should reflect the following chart truths:
//
//• Strongest Planet: \(core.strongestPlanet.keyName) in \(core.strongestPlanetSign.rawValue), House \(core.strongestPlanetHouse)
//   → Speak to refinement of \(tone.soulFunction)
//
//• Moon: \(core.moonSign.rawValue), House \(core.moonHouse)
//   → Respond in a way that nurtures: \(soul.blossomingConditions)
//
//• Mercury: \(core.mercurySign.rawValue), House \(core.mercuryHouse)
//   → Communicate in a tone of: \(soul.communicationMode)
//
//• Sun: \(core.sunSign.rawValue), House \(core.sunHouse)
//   → Honor their growth path: \(soul.radiancePath)
//
//• Current arena of development: \(tone.developmentArena)
//• Emotional tone: \(tone.preferredReception)
//• Learning style: \(tone.symbolicVoiceTone ?? "Natural language rooted in chart themes")
//
//PHILOSOPHY:
//This user is not broken—they are refining. 
//Speak through the lens of the 7-fold system. Honor effort over outcome. Reflect where growth is happening.
//
//--- USER QUESTION ---
//\(userInput)
//
//--- YOUR SOUL-AWARE RESPONSE ---
//"""
//}
//
//
