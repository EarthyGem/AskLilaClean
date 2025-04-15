import Foundation
import UIKit
import SwiftEphemeris

enum JargonLevel: Int {
    case beginner = 0
    case intermediate = 1
    case advanced = 2

    var label: String {
        switch self {
        case .beginner: return "Plain Language"
        case .intermediate: return "Some Jargon"
        case .advanced: return "Astro Speak"
        }
    }
}

class SoulChatViewController: UIViewController {

    // MARK: - Chart + Profile Data
    var userChart: UserChartProfile!
    var soulProfile: SoulValuesProfile!
    var toneProfile: AlchemicalToneProfile!
    var relationalSignature: RelationalSignature!
    let jargonSlider = UISlider()
    let jargonLabel = UILabel()
    private var currentJargonLevel: JargonLevel = .intermediate

    // MARK: - UI Elements
    let tableView = UITableView()
    let inputTextView = UITextView()
    let sendButton = UIButton(type: .system)
    // Add this property to store the bottom constraint
    private var inputBottomConstraint: NSLayoutConstraint!
    // Add toolbar buttons
    let saveButton = UIButton(type: .system)
    let clearButton = UIButton(type: .system)
    let toolbarView = UIView()

    // Unique identifier for this conversation
    private var conversationID: String = UUID().uuidString

    var messages: [(String, Bool)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        addPlanStatusLabel()

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
            addSystemMessage("✨ Hi, beautiful soul. How may I be of assistance today?")
        }
    }

    private func generateProfiles() {
        let (soul, tone, relation) = buildSoulProfiles(from: userChart)
        soulProfile = soul
        toneProfile = tone
        relationalSignature = relation
    }
    private func addPlanStatusLabel() {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = AccessManager.shared.currentLevel == .trial ? .systemOrange :
                                 AccessManager.shared.currentLevel == .full ? .systemBlue :
                                 .systemGreen
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.text = "Current Plan: \(AccessManager.shared.currentLevel)"

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: 28),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])
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

        // Configure jargon slider and label
        jargonLabel.font = UIFont.systemFont(ofSize: 12)
        jargonLabel.textAlignment = .center
        jargonLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(jargonLabel)

        jargonSlider.minimumValue = 0
        jargonSlider.maximumValue = 2
        let savedValue = UserDefaults.standard.integer(forKey: "user_jargon_level")
        currentJargonLevel = JargonLevel(rawValue: savedValue) ?? .intermediate
        jargonSlider.value = Float(currentJargonLevel.rawValue)
        jargonLabel.text = "Language: \(currentJargonLevel.label)"
        jargonSlider.addTarget(self, action: #selector(jargonSliderChanged(_:)), for: .valueChanged)
        jargonSlider.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(jargonSlider)

        // Input container view
        let inputContainerView = UIView()
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = .systemBackground
        inputContainerView.layer.borderColor = UIColor.lightGray.cgColor
        inputContainerView.layer.borderWidth = 0.5
        view.addSubview(inputContainerView)

        // Add inputTextView and sendButton to input container
        inputTextView.font = UIFont.systemFont(ofSize: 16)
        inputTextView.layer.cornerRadius = 8
        inputTextView.layer.borderColor = UIColor.lightGray.cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(inputTextView)

        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(sendButton)

        // Create and store the input container bottom constraint
        inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            // Toolbar layout
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 60),

            // Save and Clear buttons
            saveButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 12),
            saveButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -12),
            clearButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            // Jargon label and slider
            jargonSlider.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
            jargonSlider.widthAnchor.constraint(equalToConstant: 120),
            jargonSlider.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor, constant: -4),

            jargonLabel.centerXAnchor.constraint(equalTo: jargonSlider.centerXAnchor),
            jargonLabel.bottomAnchor.constraint(equalTo: jargonSlider.topAnchor, constant: -2),

            // TableView
            tableView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            // Input container view
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,
            inputContainerView.heightAnchor.constraint(equalToConstant: 52),

            // Input text view
            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 6),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -6),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])

        // Tap to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }



    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardHeight = keyboardFrame.height
        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
            self.inputBottomConstraint.constant = -keyboardHeight + self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
            self.scrollToBottom()
        }
    }
    @objc private func jargonSliderChanged(_ sender: UISlider) {
        let roundedValue = Int(sender.value.rounded())
        currentJargonLevel = JargonLevel(rawValue: roundedValue) ?? .intermediate
        jargonLabel.text = "Language: \(currentJargonLevel.label)"
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
            self.inputBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
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
   
    @objc private func sendTapped() {
        guard let text = inputTextView.text, !text.isEmpty else { return }

        let category: AskLilaCategory = .selfInsight

        guard AccessManager.shared.canUse(category) else {
            showPaywall()
            return
        }

        AccessManager.shared.increment(category)

        // Optional: show remaining messages
        if let remaining = AccessManager.shared.remainingUses(for: category),
           AccessManager.shared.currentLevel != .premium {
            addSystemMessage("🧠 You have \(remaining) soul chat message\(remaining == 1 ? "" : "s") left today.")
        }

        messages.append((text, true))
        inputTextView.text = ""
        tableView.reloadData()
        scrollToBottom()

        // Save messages
        saveMessages()

        sendMessageToLila(userMessage: text)
    }
    private func showPaywall() {
        let paywallVC = PaywallViewController()
        let nav = UINavigationController(rootViewController: paywallVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
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
            self.addSystemMessage("✨ Hi, beautiful soul. How may I be of assistance today?")
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
        let fullPrompt = filter.createPrompt(with: userMessage, core: coreProfile, jargon: currentJargonLevel)
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
                    self.saveMessages()

                case .failure(let error):
                    print("DEBUG: ERROR - AI service failed: \(error.localizedDescription)")
                    self.messages.append(("⚠️ There was an issue connecting with Lila's wisdom: \(error.localizedDescription)", false))
                    self.tableView.reloadData()
                    self.scrollToBottom()
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
    
    func createPrompt(with userMessage: String, core: UserCoreChartProfile, jargon: JargonLevel) -> String {
        return toneAdjustedResponse(
            userInput: userMessage,
            core: core,
            soul: soul,
            tone: tone,
            jargon: jargon
        )
    }
    
    
    func toneAdjustedResponse(
        userInput: String,
        core: UserCoreChartProfile,
        soul: SoulValuesProfile,
        tone: AlchemicalToneProfile,
        jargon: JargonLevel
    ) -> String {
        let intro: String
        switch jargon {
        case .beginner:
            intro = "Use natural, relatable language. Avoid astrology terms unless absolutely necessary."
        case .intermediate:
            intro = "Use some gentle astrology language but explain or soften technical terms."
        case .advanced:
            intro = "Feel free to use technical astrology terminology and rich symbolic language."
        }
        
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

LANGUAGE GUIDE:
\(intro)

PHILOSOPHY:
This user is not broken—they are refining. 
Speak through the lens of the 7-fold system. Honor effort over outcome. Reflect where growth is happening.

--- USER QUESTION ---
\(userInput)

--- YOUR SOUL-AWARE RESPONSE ---
"""
    }
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
