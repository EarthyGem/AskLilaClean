//
//
//  SoulChat.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/4/25.
//

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
        addSystemMessage("✨ Hi, beautiful soul. I’m here to walk beside you. Ask me anything on your path.")
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
            inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            inputTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputTextView.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -8)
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
        
        sendMessageToLila(userMessage: text)
    }
    
    private func addSystemMessage(_ text: String) {
        messages.append((text, false))
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
                case .failure(let error):
                    print("DEBUG: ERROR - AI service failed: \(error.localizedDescription)")
                    self.messages.append(("⚠️ There was an issue connecting with Lila's wisdom: \(error.localizedDescription)", false))
                    self.tableView.reloadData()
                    self.scrollToBottom()
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


