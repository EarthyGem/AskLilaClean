//
//  New.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/29/25.
//

import Foundation
//
//  MyAgentChatController.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.

import Foundation
import SwiftEphemeris
import UIKit
import CoreData
import Firebase
import FirebaseAuth
enum ChartContextType {
    case natal
    case synastry
    case past
    case future
    case present
}

class MyAgentChatController: UIViewController {
    // MARK: - Properties
    var chartCake: ChartCake!
    var otherChart: ChartCake?
 var transitChartCake: ChartCake?
    var copiedMessage: String?
    private var isAdmin = false
    private var currentConversationId: String?
    private var chartSummaryContext: String?
    private var useSuperchargedAgent = UserDefaults.standard.bool(forKey: "useSuperchargedAgent")
    var userChart: UserChartProfile!
    private let jargonSlider = UISlider()
    private let jargonLabel = UILabel()
    private var currentJargonLevel: JargonLevel = .intermediate
    private var hasDismissedTrialBanner = false

    private var trialBannerView: TrialBannerView?
    // UI Elements
    private let chatTableView = UITableView()
    private let messageInputField: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let sendButton = UIButton()
    var messages: [(String, Bool)] = [] // (Message, isUser)

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // Loading messages for better UX
    private let loadingMessages: [String] = [
        "Lila takes a moment to glance over your chart...",
        "Giving this a thoughtful look through the lens of your chart...",
        "Taking a step back to see the bigger picture in your chart...",
        "Pausing to reflect on the patterns unfolding for you...",
        "Looking at how these planetary movements connect to your path...",
        "Tracing the story your transits and progressions are telling...",
        "Noticing which planetary cycles are shaping this moment...",
        "Considering what's being activated in your chart right now...",
        "Observing how today's sky interacts with your natal blueprint...",
        "Giving this the attention it deserves before offering insight..."
    ]
    func isAdminUser(completion: @escaping (Bool) -> Void) {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                completion(false)
                return
            }
            let db = Firestore.firestore()
            db.collection("users").document(currentUserId).getDocument { (document, error) in
                if let document = document, document.exists, let isAdmin = document.data()?["isAdmin"] as? Bool {
                    completion(isAdmin)
                } else {
                    completion(false)
                }
            }
        }




    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let expiredDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
    //    UserDefaults.standard.set(expiredDate, forKey: "trialStartDate")

        setupKeyboardNotifications()
        setupUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.setupNavigationBar()
        }
        // Initialize trial if needed
          TrialUsageManager.shared.initializeTrialIfNeeded()
          
          // Setup trial banner if user is in trial mode
        //  setupTrialBannerIfNeeded()
        startNewConversation()
        print(chartCake.natal.asteroids.compactMap {$0.formatted})
        print("💬 AgentChat loaded with chartCake: \(chartCake?.name ?? "nil")")
           
           // Load previous conversations instead of just adding greeting message
          
        if let uid = Auth.auth().currentUser?.uid {
            ChartContextManager.shared.fetchChartSummary(for: uid) { [weak self] summary in
                guard let self = self, let summary = summary else { return }
                self.chartSummaryContext = generateChartContextPrompt(from: summary)
            }
        }

        Analytics.logEvent("specialFeatures_tabeView_viewed", parameters: nil)

    

        // Initial greeting message
        let greetingMessage = """
        💁🏽‍♀️ Welcome to Ask Lila!.

        ✨ How to Use Me:
        - You can ask me a question about your chart.
        - Tap the 📅 calendar to ask about a specific date.
        - Tap the 👥 people icon to add another person for relationship insights.
        - Tap the AI 🧠 icon to change the AI service powering me.
        """
        print("💬 AgentChat loaded with chartCake: \(chartCake?.name ?? "nil")")
        messages.append((greetingMessage, false))
        chatTableView.reloadData()
    }
    @objc private func jargonSliderChanged(_ sender: UISlider) {
        let roundedValue = Int(sender.value.rounded())
        currentJargonLevel = JargonLevel(rawValue: roundedValue) ?? .intermediate
        jargonLabel.text = "Language: \(currentJargonLevel.label)"
        UserDefaults.standard.set(roundedValue, forKey: "user_jargon_level")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 🧪 Simulate expired 24-hour trial
        let expiredDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        UserDefaults.standard.set(expiredDate, forKey: "trialStartDate")
        print("🧪 Trial start forced to: \(expiredDate)")

        // Optional: hit the usage cap too
        UserDefaults.standard.set(2, forKey: "trialUsage_relationship") // max = 2 for trial

        updateTrialBanner()
    }


    @objc private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty else { return }

        // Clear the input field IMMEDIATELY after sending
        messageInputField.text = ""
        textViewDidChange(messageInputField)

        let category: AskLilaCategory
        if otherChart != nil {
            category = .relationship
        } else if transitChartCake != nil {
            category = .dateInsight
        } else {
            category = .selfInsight
        }

//        func isRunningOnSimulator() -> Bool {
//            #if targetEnvironment(simulator)
//            return true
//            #else
//            return false
//            #endif
//        }

     //   let isSimulator = isRunningOnSimulator()

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            Task {
                await appDelegate.updateSubscriptionLevel()

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    print("⚙️ Current subscription level: \(AccessManager.shared.currentLevel)")

//                    if !isSimulator {
//                        if !AccessManager.shared.canUse(category) {
//                            Swift.print("🚫 No access for \(category) with level \(AccessManager.shared.currentLevel)")
//
//                            if AccessManager.shared.currentLevel == .full,
//                               !FullAccessManager.shared.canUse(category) {
//                                let upgradeVC = UpgradeToPremiumViewController()
//                                let nav = UINavigationController(rootViewController: upgradeVC)
//                                self.present(nav, animated: true)
//                            } else {
//                                let paywall = PaywallViewController()
//                                let nav = UINavigationController(rootViewController: paywall)
//                                self.present(nav, animated: true)
//                            }
//
//                            return
//                        } else {
//                            AccessManager.shared.increment(category)
//                        }
//                    }

                    let loadingMessage = self.contextAwareLoadingMessage()
                    self.messages.append((loadingMessage, false))
                    self.chatTableView.reloadData()
                    self.scrollToBottom()
                    self.loadingIndicator.startAnimating()

                    let chartToUse = self.transitChartCake ?? self.chartCake

                    let readingType: String
                    if self.otherChart != nil {
                        readingType = "SYNASTRY/RELATIONSHIP"
                    } else if self.transitChartCake != nil {
                        readingType = "TRANSIT & PROGRESSION"
                    } else {
                        readingType = "NATAL CHART"
                    }

                    let transitText = self.buildFourNetProfileString(
                        transitDate: chartToUse?.transitDate ?? Date(),
                        chartCake: chartToUse!
                    )

                    print("🔍 Performing \(readingType) reading")
                    var fullPrompt = ""

                    if let context = self.chartSummaryContext {
                        fullPrompt += """
                        🧠 CHART MEMORY CONTEXT:
                        \(context)

                        """
                    }

                    if readingType == "TRANSIT & PROGRESSION",
                       let timeContext = UserDefaults.standard.dictionary(forKey: "transitTimeContext") {
                        let isPast = timeContext["isPast"] as? Bool ?? false
                        let isFuture = timeContext["isFuture"] as? Bool ?? false
                        let yearsApart = timeContext["yearsApart"] as? Int ?? 0
                        let monthsApart = timeContext["monthsApart"] as? Int ?? 0
                        let daysApart = timeContext["daysApart"] as? Int ?? 0

                        fullPrompt += """
                        ⏳ TIME CONTEXT:
                        - \(isPast ? "Past" : isFuture ? "Future" : "Current") date
                        - \(yearsApart > 0 ? "\(yearsApart) years" : monthsApart > 0 ? "\(monthsApart) months" : "\(daysApart) days") \(isPast ? "ago" : "from now")

                        """
                    }

                    let rawJargonLevel = UserDefaults.standard.integer(forKey: "user_jargon_level")
                    let currentJargonLevel = JargonLevel(rawValue: rawJargonLevel) ?? .intermediate

                    let jargonGuide = """
                    LANGUAGE GUIDE:
                    \(currentJargonLevel == .beginner ? "Use plain, natural language. Avoid astrology jargon unless absolutely necessary." :
                     currentJargonLevel == .intermediate ? "Use soft astrology terms. Define or explain any complex words." :
                     "Use full astrological terminology. User is fluent.")
                    """

                    let formattedPrompt = """
                    READING TYPE: \(readingType)

                    \(jargonGuide)

                    \(fullPrompt)

                    USER QUESTION: \(text)
                    """

                    Analytics.logEvent("regular_message_sent", parameters: [
                        "reading_type": readingType,
                        "message_length": text.count,
                        "has_context": self.chartSummaryContext != nil
                    ])

                    LilaAgentManager.shared.sendMessageToAgent(
                        prompt: formattedPrompt,
                        userChart: chartToUse,
                        otherChart: self.otherChart
                    ) { [weak self] response in
                        guard let self = self else { return }

                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.messages.removeLast()
                            self.chatTableView.reloadData()

                            if let response = response {
                                self.messages.append((response, false))
                                self.chatTableView.reloadData()
                                self.scrollToBottom()
                            } else {
                                self.messages.append(("I'm sorry, I encountered an error while processing your request. Please try again.", false))
                                self.chatTableView.reloadData()
                                self.scrollToBottom()
                            }
                        }
                    }
                }
            }
        } else {
//            if !isSimulator {
//                if !AccessManager.shared.canUse(category) {
//                    Swift.print("🚫 No access, showing appropriate paywall fallback.")
//
//                    if AccessManager.shared.currentLevel == .full,
//                       !FullAccessManager.shared.canUse(category) {
//                        let upgradeVC = UpgradeToPremiumViewController()
//                        let nav = UINavigationController(rootViewController: upgradeVC)
//                        present(nav, animated: true)
//                    } else {
//                        let paywall = PaywallViewController()
//                        let nav = UINavigationController(rootViewController: paywall)
//                        present(nav, animated: true)
//                    }
//
//                    return
//                } else {
//                    AccessManager.shared.increment(category)
//                }
//            }
        }
    }


    private func setupTrialBannerIfNeeded() {
        print("🧭 Checking banner for subscription level: \(AccessManager.shared.currentLevel)")

        // Respect session-level dismiss
        if hasDismissedTrialBanner {
            print("🚫 Banner dismissed earlier this session.")
            trialBannerView?.removeFromSuperview()
            trialBannerView = nil
            chatTableView.contentInset = .zero
            return
        }

        // Remove any existing banner before adding new one
        trialBannerView?.removeFromSuperview()
        trialBannerView = nil
        chatTableView.contentInset = .zero

        let banner = TrialBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        banner.onDismiss = {
            self.hasDismissedTrialBanner = true
            self.trialBannerView = nil
            self.chatTableView.contentInset = .zero
        }

        switch AccessManager.shared.currentLevel {
        case .introOffer:
            print("🎁 Showing Intro Offer Banner")
            banner.configure(for: .introOffer)

        case .trial:
            if let endDate = TrialUsageManager.shared.trialEndDate {
                print("⏳ Showing Sneak Peek Banner")
                banner.configure(for: .sneakPeek(endDate: endDate))
            } else {
                print("❌ Trial mode active but no trial end date")
                return
            }

        case .full:
            print("🌿 Showing Full Access Banner")
            banner.configure(for: .full)

        case .premium:
            print("💫 Showing Premium Access Banner")
            banner.configure(for: .premium)
        }

        trialBannerView = banner
        chatTableView.contentInset = UIEdgeInsets(top: 70, left: 0, bottom: 0, right: 0)
    }



 
       // Add this method to update the banner visibility when subscription status changes
       func updateTrialBanner() {
           setupTrialBannerIfNeeded()
       }
    private func startNewConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let conversationId = UUID().uuidString
        currentConversationId = conversationId

        let metadata: [String: Any] = [
            "startedAt": Timestamp(date: Date()),
            "chartName": chartCake?.name ?? "Unknown",
            "readingType": otherChart != nil ? "SYNASTRY" :
                            transitChartCake != nil ? "TRANSIT" : "NATAL"
        ]

        db.collection("users").document(uid)
            .collection("conversations").document(conversationId)
            .setData(metadata)

        print("💾 Started new conversation: \(conversationId)")
    }


    private func setupNavigationBar() {
        
        // 🌦️ South Node Story
        let showForecastButton = makeEmojiBarButton("🌦️", action: #selector(showForecastTapped))
        
        // 📖 South Node Story
        let showStoryButton = makeEmojiBarButton("📖", action: #selector(showSouthNodeStoryTapped))
        
        // 🧚🏿‍♂️ Soul Stats
        let statsButton = makeEmojiBarButton("🧚🏿‍♂️", action: #selector(showStatsTapped))

        // 📅 Select Date
        let selectDateButton = makeEmojiBarButton("📅", action: #selector(selectDateTapped))

        // 🧑‍🤝‍🧑 Select Partner
        let addPartnerButton = makeEmojiBarButton("👥", action: #selector(selectPartnerTapped))

        // 🧠 Select AI Service
        let selectAIServiceButton = makeEmojiBarButton("🧠", action: #selector(selectAIServiceTapped))

        // ⚙️ Edit Chart
        let editChartButton = makeEmojiBarButton("⚙️", action: #selector(editChartTapped))

        // 🕰️ Conversation History
        let historyButton = makeEmojiBarButton("🗂️", action: #selector(showConversationHistory))

        // 🌼 Final nav layout
        navigationItem.rightBarButtonItems = [addPartnerButton, selectDateButton, selectAIServiceButton, statsButton]
        navigationItem.leftBarButtonItems = [editChartButton,showStoryButton, historyButton, showForecastButton ]

        updateAIServiceIndicator()
    }

    private func makeEmojiBarButton(_ emoji: String, action: Selector) -> UIBarButtonItem {
        let label = UILabel()
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: 28) // Set once for all buttons
        label.sizeToFit()
        label.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tapGesture)

        return UIBarButtonItem(customView: label)
    }

    
  
    

  
    @objc private func showConversationHistory() {
        // Present the AI service selector
        let historyVC = ConversationHistoryViewController()

        let navController = UINavigationController(rootViewController: historyVC)
        present(navController, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .white
        title = "Ask Lila"

        // Add an input container view to hold the text field and button
        let inputContainerView = UIView()
        inputContainerView.backgroundColor = .white
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)

        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.separatorStyle = .none
        chatTableView.translatesAutoresizingMaskIntoConstraints = false
        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = 50
        view.addSubview(chatTableView)

        // Set up message input field
        messageInputField.isScrollEnabled = false
        messageInputField.font = UIFont.systemFont(ofSize: 16)
        messageInputField.layer.borderColor = UIColor.lightGray.cgColor
        messageInputField.layer.borderWidth = 1
        messageInputField.layer.cornerRadius = 5
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        messageInputField.delegate = self
        inputContainerView.addSubview(messageInputField)

        sendButton.setTitle("Send", for: .normal)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 5
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(sendButton)

        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Input container view constraints
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 60),

            // Chat table view constraints
            chatTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            // Message input field constraints
            messageInputField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageInputField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            messageInputField.heightAnchor.constraint(equalToConstant: 40),

            // Send button constraints
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 80),
            sendButton.heightAnchor.constraint(equalToConstant: 40),

            // Loading indicator constraints
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -10)
        ])

        // Add tap gesture recognizer to dismiss keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        chatTableView.addGestureRecognizer(tapGesture)
    }
    

    @objc private func toggleAgentMode(_ sender: UISwitch) {
        useSuperchargedAgent = sender.isOn
        let mode = useSuperchargedAgent ? "Supercharged" : "Classic"
        addSystemMessage("🔧 Agent mode set to: **\(mode)**")
    }

    private func showAddPartnerScreen() {
        // Create a PartnerViewController
        let addPartnerVC = PartnerViewController()
        addPartnerVC.title = "Add Partner Chart"
        
        // Set completion handler to refresh charts when done
        addPartnerVC.onProfileCompletion = { [weak self] in
            guard let self = self else { return }
            
            // Add a message to notify the user
            self.addSystemMessage("Partner chart has been added. You can now select it from the partners menu.")
            
            // Optionally, you could also automatically reopen the partner selection menu
            // self.selectPartnerTapped()
        }
        
        // Present the view controller
        let navController = UINavigationController(rootViewController: addPartnerVC)
        present(navController, animated: true)
    }

    // Helper method to add system messages
   func addSystemMessage(_ text: String) {
        messages.append((text, false))
        chatTableView.reloadData()
        scrollToBottom()
    }
    // Then update the keyboard handling methods
    // MARK: - Keyboard Handling
    // MARK: - Keyboard Handling
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add this to handle app returning from background
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    // Override viewWillAppear instead of trying to observe it
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset keyboard handling when view appears
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        // Get the keyboard size
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let keyboardHeight = keyboardFrame.height
        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)
        
        // Find the input container view
        if let inputContainerView = self.view.subviews.first(where: { $0.subviews.contains(self.messageInputField) }) {
            let bottomConstraint = self.view.constraints.first {
                ($0.firstItem === inputContainerView && $0.firstAttribute == .bottom) ||
                ($0.secondItem === inputContainerView && $0.secondAttribute == .bottom)
            }
            
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
                // Update the constraint to adjust for keyboard height
                bottomConstraint?.constant = -keyboardHeight + self.view.safeAreaInsets.bottom
                self.view.layoutIfNeeded()
                self.scrollToBottom()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)
        
        // Find the input container view
        if let inputContainerView = self.view.subviews.first(where: { $0.subviews.contains(self.messageInputField) }) {
            let bottomConstraint = self.view.constraints.first {
                ($0.firstItem === inputContainerView && $0.firstAttribute == .bottom) ||
                ($0.secondItem === inputContainerView && $0.secondAttribute == .bottom)
            }
            
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
                // Reset the constraint
                bottomConstraint?.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }

    // Handle returning to the view
    @objc private func applicationWillEnterForeground() {
        // Force layout refresh when app returns to foreground
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    // Don't forget to clean up observers in deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    @objc private func viewWillAppear() {
        // Reset keyboard handling when view appears
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

 
    private func contextAwareLoadingMessage() -> String {
        if let _ = otherChart {
            // Synastry
            let options = [
                "Tuning into the chemistry between your charts...",
                "Exploring the energetic bridge between you two...",
                "Looking at how your planetary patterns connect...",
                "Reading between the relational lines...",
                "Exploring the dynamic dance of your charts..."
            ]
            return options.randomElement()!
        } else if let date = transitChartCake?.transitDate {
            let now = Date().adjust(for: .startOfDay)!
            let selected = date.adjust(for: .startOfDay)!

            if selected < now {
                let options = [
                    "Looking back at how the sky was shaping you then...",
                    "Tracing the past alignments that may have influenced that moment...",
                    "Reflecting on the patterns at play during that time...",
                    "Reviewing the cosmic setup from that chapter...",
                    "Analyzing past energies and what they stirred..."
                ]
                return options.randomElement()!
            } else if selected > now {
                let options = [
                    "Peeking into upcoming celestial patterns...",
                    "Scanning forward for the energies approaching you...",
                    "Forecasting what the stars are setting in motion...",
                    "Looking ahead at your unfolding astrological weather...",
                    "Casting insight into the future rhythms of your chart..."
                ]
                return options.randomElement()!
            } else {
                let options = [
                    "Tuning into today’s planetary influences...",
                    "Checking how today’s sky is interacting with your chart...",
                    "Looking at what’s being activated right now...",
                    "Reflecting on your current cosmic moment...",
                    "Analyzing today's energetic imprint on your path..."
                ]
                return options.randomElement()!
            }
        } else {
            // Natal chart default
            let options = [
                "Taking a deep look at the blueprint of your being...",
                "Reflecting on the foundational energies you were born with...",
                "Studying the original imprint of your chart...",
                "Consulting the core themes written in your stars...",
                "Centering into the map of your inner universe..."
            ]
            return options.randomElement()!
        }
    }

    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Keyboard Handling
   
    func topAspects(chartCake: ChartCake,
        to planet: CelestialObject,
        in aspectsScores: [CelestialAspect: Double],
        limit: Int = 2
    ) -> [NatalAspectScore] {
        let sorted = chartCake.natal
            .filterAndFormatNatalAspects(by: planet, aspectsScores: aspectsScores)
            .sorted { $0.value > $1.value }  // Explicit sort for clarity

        return sorted.prefix(limit)
            .map { NatalAspectScore(aspect: $0.key, score: $0.value) }
    }

    private func scrollToBottom() {
        guard chatTableView.numberOfSections > 0 else { return }

        let numberOfRows = chatTableView.numberOfRows(inSection: chatTableView.numberOfSections - 1)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows - 1, section: chatTableView.numberOfSections - 1)
            chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    func buildUserChartProfile(from cake: ChartCake) -> UserChartProfile {
        let natal = cake.natal
        let aspectsScores = natal.allCelestialAspectScoresByAspect()

        let strongest = cake.strongestPlanet
        let strongestCoord = natal.planets.first { $0.body == strongest } ?? natal.sun
        let strongestHouse = natal.houseCusps.house(of: strongestCoord).number
        let ruledHouses = natal.houseCusps
            .influencedCoordinatesHouses(for: strongestCoord)
            .map { $0.number }
            .filter { $0 != strongestHouse }

        let sunHouse = natal.houseCusps.house(of: natal.sun).number
        let moonHouse = natal.houseCusps.house(of: natal.moon).number
        let mercury = natal.planets.first(where: { $0.body == cake.natal.mercury.body })!
        let mercuryHouse = natal.houseCusps.house(of: mercury).number

        let ascSign = natal.ascendantCoordinate.sign
        let ascRulers = natal.houseCusps.customRulersForAllCusps()
            .filter { $0.key.number == 1 }
            .flatMap { $0.value }

        let ascRulerCoordinates: [Coordinate] = ascRulers.compactMap { ruler in
            natal.planets.first(where: { $0.body == ruler })
        }

        let ascRulerHouses: [Int] = ascRulerCoordinates.map { natal.houseCusps.house(of: $0).number }
        let ascRulerSigns: [Zodiac] = ascRulerCoordinates.map { $0.sign }

        let ascRulerAspects: [NatalAspectScore] = ascRulers.flatMap {
            topAspects(chartCake: cake, to: $0, in: aspectsScores)
        }

        let sunPower = cake.planetScores[natal.sun.body] ?? 0.0
        let moonPower = cake.planetScores[natal.moon.body] ?? 0.0
        let ascendantPower = cake.planetScores[natal.ascendantCoordinate.body] ?? 0.0
        let ascendantRulerPowers = ascRulers.map { cake.planetScores[$0] ?? 0.0 }

        return UserChartProfile(
            name: cake.name ?? "Unnamed",
            birthDate: natal.birthDate,
            sex: cake.sex,

            strongestPlanet: strongest,
            strongestPlanetSign: cake.strongestPlanetSignSN,
            strongestPlanetHouse: strongestHouse,
            strongestPlanetRuledHouses: ruledHouses,

            sunSign: natal.sun.sign,
            sunHouse: sunHouse,
            sunPower: sunPower,
            topAspectsToSun: topAspects(chartCake: cake, to: natal.sun.body, in: aspectsScores),

            moonSign: natal.moon.sign,
            moonHouse: moonHouse,
            moonPower: moonPower,
            topAspectsToMoon: topAspects(chartCake: cake, to: natal.moon.body, in: aspectsScores),

            ascendantSign: ascSign,
            ascendantPower: ascendantPower,
            topAspectsToAscendant: topAspects(chartCake: cake, to: natal.ascendantCoordinate.body, in: aspectsScores),

            mercurySign: mercury.sign,
            mercuryHouse: mercuryHouse,

            ascendantRulerSigns: ascRulerSigns,
            ascendantRulers: ascRulers,
            ascendantRulerHouses: ascRulerHouses,
            ascendantRulerPowers: ascendantRulerPowers,
            topAspectsToAscendantRulers: ascRulerAspects,

            dominantHouseScores: cake.houseScoresSN,
            dominantSignScores: cake.signScoresSN,
            dominantPlanetScores: cake.planetScoresSN,

            mostHarmoniousPlanet: cake.mostHarmoniousPlanetSN,
            mostDiscordantPlanet: cake.mostDiscordantPlanetSN,
            topAspectsToStrongestPlanet: topAspects(chartCake: cake, to: strongest, in: aspectsScores)
        )
    }


    @objc private func showStatsTapped() {
        guard let chart = chartCake else {
            addSystemMessage("⚠️ No chart available to analyze.")
            return
        }

        // 🌱 Step 1: Build the full chart profile (the input for all soul work)
        let fullProfile = buildUserChartProfile(from: chart)

        // 🌿 Step 2: Initialize the chat and pass in this core profile
        let soulChatVC = SoulChatViewController()
        soulChatVC.userChart = fullProfile // ✅ Now correct type

        let navController = UINavigationController(rootViewController: soulChatVC)
        present(navController, animated: true)

        addSystemMessage("📊 Here's a deep dive into your astro-soul story — including your evolutionary tone, learning arenas, and your radiant path.")
    }

    @objc private func editChartTapped() {


            // Simple direct approach: Create and present the edit view controller directly
            let editVC = SettingsMenuViewController()
            editVC.chartCake = self.chartCake

            // Present modally with a navigation controller
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true) {
                print("✅ Edit chart screen presented successfully")

            }
        }
    

    @objc func showSouthNodeStoryTapped() {
        // Create the South Node Story view controller
        let storyVC = SouthNodeStoryViewController()
        storyVC.chartCake = transitChartCake ?? chartCake // Use active chart (transit or natal)
        storyVC.lilaViewController = self // Set reference to this view controller
        
        // Present it with a navigation controller
        let navController = UINavigationController(rootViewController: storyVC)
        present(navController, animated: true)
        
        // Add a system message to inform the user
        addSystemMessage("📚 I've opened the South Node Storyteller. This will create a past-life story based on your South Node placement, which represents karmic patterns from previous incarnations.")
    }
    
    private func loadPreviousConversations() {
        // Clear existing messages before loading saved ones
        messages.removeAll()
        
        // Add the greeting message first
        let greetingMessage = """
        💁🏽‍♀️ Welcome to Ask Lila! I'm Lila, your AI astrology partner.

        ✨ How to Use Me:
        - You can ask me a question about your chart.
        - Tap the 📅 calendar to ask about a specific date.
        - Tap the 👥 people icon to add another person for relationship insights.
        - Tap the AI 🧠 icon to change the AI service powering me.
        """
        messages.append((greetingMessage, false))
        
        // Get conversation history
        let conversationHistory = LilaMemoryManager.shared.fetchConversationHistory()
        
        // Only add conversation history if there are messages
        if !conversationHistory.isEmpty {
            for message in conversationHistory {
                guard let role = message.role, let content = message.content else { continue }
                messages.append((content, role == "user"))
            }
        }
        
        chatTableView.reloadData()
        scrollToBottom()
    }

    private func updateAIServiceIndicator() {
        // Get currently selected service
        let selectedServiceIndex = UserDefaults.standard.integer(forKey: "selectedAIService")

        // Display small badge with service name somewhere in UI
        if let serviceNameItem = navigationItem.rightBarButtonItems?.last {
            serviceNameItem.tintColor = getColorForService(index: selectedServiceIndex)
        }
    }

    private func getColorForService(index: Int) -> UIColor {
        switch index {
        case 0: return .systemGreen  // OpenAI
        case 1: return .systemPurple // Claude
        case 2: return .systemOrange // HuggingFace
        default: return .systemBlue
        }
    }

    // MARK: - Action Handlers
    @objc private func selectAIServiceTapped() {
        // Present the AI service selector
        let aiServiceSelector = AIServiceController()
        aiServiceSelector.delegate = self
        let navController = UINavigationController(rootViewController: aiServiceSelector)
        present(navController, animated: true)
    }

    @objc private func selectDateTapped() {
        let pickerVC = DatePickerSheetViewController()
        pickerVC.modalPresentationStyle = .pageSheet

        // Optional: make it scrollable if you plan to add more in future
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        pickerVC.onDateSelected = { [weak self] date in
            guard let self = self else { return }
            self.transitChartCake = nil
            self.createTransitChart(for: date)
        }

        present(pickerVC, animated: true)
    }


    @objc private func selectPartnerTapped() {
        let loadingAlert = UIAlertController(title: "Loading", message: "Fetching charts...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        fetchAllCharts { [weak self] (charts: [ChartEntity]) in
            guard let self = self else { return }
            
            print("📊 Total fetched charts: \(charts.count)")
            
            let currentUserName = self.chartCake.name.trimmingCharacters(in: .whitespacesAndNewlines)
            var uniqueCharts: [ChartEntity] = []
            var seenNames = Set<String>()
            
            for chart in charts {
                guard let name = chart.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                    print("⚠️ Skipping chart with missing name: \(chart)")
                    continue
                }
                
                // Skip current user's own chart
                if name == currentUserName {
                    print("⛔️ Skipping user's own chart: \(name)")
                    continue
                }

                if seenNames.contains(name) {
                    print("🔁 Duplicate name found: \(name) — skipping")
                } else {
                    print("✅ Adding chart: \(name)")
                    seenNames.insert(name)
                    uniqueCharts.append(chart)
                }
            }
            
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    let alert = UIAlertController(title: "Select a Partner",
                                                  message: "Choose a chart for synastry analysis.",
                                                  preferredStyle: .actionSheet)

                    if uniqueCharts.isEmpty {
                        print("🚫 No partner charts available")
                        alert.message = "No partner charts found. Please add a partner chart."
                    } else {
                        print("🧩 Showing \(uniqueCharts.count) partner options")
                        for chart in uniqueCharts {
                            let name = chart.name ?? "Unknown"
                            alert.addAction(UIAlertAction(title: name, style: .default, handler: { _ in
                                self.setPartnerChart(chart)
                            }))
                        }
                    }

                    alert.addAction(UIAlertAction(title: "Add New Partner", style: .default, handler: { _ in
                        self.showAddPartnerScreen()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                    // iPad fix
                    if let popover = alert.popoverPresentationController {
                        popover.barButtonItem = self.navigationItem.rightBarButtonItems?.first(where: { $0.image == UIImage(systemName: "person.2") })
                        popover.permittedArrowDirections = .up
                    }

                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Helper Methods

    func fetchAllCharts(completion: @escaping ([ChartEntity]) -> Void) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request: NSFetchRequest<ChartEntity> = ChartEntity.fetchRequest()

        do {
            let charts = try context.fetch(request)
            print("📦 DEBUG: Found \(charts.count) total charts")
            for chart in charts {
                print("🔍 Chart: \(chart.name ?? "Unnamed")")
            }
            completion(charts)
        } catch {
            print("❌ ERROR fetching charts: \(error.localizedDescription)")
            completion([])
        }
    }


    func buildFourNetProfileString(transitDate: Date, chartCake: ChartCake) -> String? {


        let calendar = Calendar.current
        let now = Date()
        let isPast = transitDate < now
        let isFuture = transitDate > now
        let components = calendar.dateComponents([.year, .month, .day], from: Date(), to: transitDate)

        let yearsApart = components.year ?? 0
        let monthsApart = components.month ?? 0
        let daysApart = components.day ?? 0

        let formattedDate = DateFormatter.localizedString(from: transitDate, dateStyle: .medium, timeStyle: .none)
        let age = calculateAgeString(from: chartCake.natal.birthDate, to: transitDate)

        let netOneData = chartCake.netOne()
        let netTwoData = chartCake.netTwo()
        let netThreeData = chartCake.netThree()
        let netFourData = chartCake.netFour()

        return """
                    ⏳ TIME CONTEXT:
                    - \(isPast ? "Past" : isFuture ? "Future" : "Present") date
                    - \(yearsApart > 0 ? "\(yearsApart) years" : monthsApart > 0 ? "\(monthsApart) months" : "\(daysApart) days") \(isPast ? "ago" : "from now")
                    
                    TRANSIT DATA for \(formattedDate):
                    - Most important activations: \(netOneData)
                    - Supporting activations: \(netTwoData)
                    - Slightly less important: \(netThreeData)
                    - Daily triggers: \(netFourData)
                    - This person is \(age). Please make recommendations age-appropriate.
                    
                    
                    
                    - **Transits and Progressions** reveal how life unfolds as an evolutionary journey of integration.
                    
                    Your role is to help \(chartCake.name) appreciate why **meaningful events have occurred, are occurring, and will occur**—not as random fate, but as opportunities for growth.
                    
                    💡 **Life happens for us, not to us.** Every planetary activation represents a **moment in our evolutionary path where we are ready to integrate the two planets in aspect in the 1 or more areas ruled by the natal planet being aspected**.
                    
                    🌟 How to Interpret Transits & Progressions
                    1️⃣ Use Only the Provided Data
                    Never estimate planetary movements. Use only the transits & progressions preloaded for the selected date.
                    Stick to the given chart. Avoid speculation about planetary positions.
                    
                    2️⃣ Find the Main House of Concern
                    Lila must first determine which house \(chartCake.name)'s question is about.
                    If the user asks about relationships → 7th house
                    If about career → 10th house
                    If about spiritual retreats → 12th house
                    If no house theme is obvious, ak follow up questions until a house theme becomes obvious.
                    
                    3️⃣ Prioritize Progressions to House Rulers
                    Progressions are the primary indicators of major life themes.
                    Lila must always check progressions to the house ruler first—this is the main indicator of why the experience is happening.
                    The focus is on what planets are stimulating the house ruler, revealing the Planet responsible for the event.
                    these activationg planets will either play teacher or trickster depending on well we handle them. Our job is to warn about the trickster and encourage allowing the stimulating planet to be a teacher.
                    
                    After progressions, transits to house rulers should be included to fine-tune the timing and expression of these themes.
                    ---If there are no progressions to the house rulers, skip straight to tarnsits to house rulers---
                    4️⃣ Focus Only on House Rulers
                    House rulers determine activations—NOT planets simply transiting a house.
                    A transit or progression to a house ruler is the only thing that activates the house.
                    Planets inside a house mean nothing unless they rule it.
                    All additional transits and progressions must be analyzed in the context of how they support the activation of the main house.
                    
                    
                    🔹 House Rulers =
                    ✅ Planets ruling the house cusp
                    ✅ Planets inside the house
                    ✅ Planets ruling intercepted signs
                    
                    
                    🔑 Key Rules for Interpretation
                    ✅ DO:
                    ✔ First, determine the main house of concern based on the question.... MOTHER IS TENTH HOUSE and FATHER IS 4th HOUSE
                    ✔ Check for progressions to the house ruler first—this is the main indicator of why the experience is happening.
                    ✔ Next, analyze what planets are aspecting the house ruler to see what planets are providing the evolutionry impetus for the event.
                    ✔ Only after progressions, check transits to house rulers to fine-tune the timing of the themes.
                    ✔ Frame any additional transits in terms of how they support the activation of the main house.
                    ✔ Always ask a follow-up question about whether \(chartCake.name) would like to know more about how the other current activations to their chart can contribute to the main theme
                    ✔ Emphasize the evolutionary lesson of the aspect.
                    ✔ Frame challenges as growth opportunities rather than fixed fates.
                    ✔ Show how the integration of planetary energies supports soul evolution.
                    
                    🚫 DON'T:
                    ❌ Ignore progressions—progressions are always the first layer of interpretation.
                    ❌ Prioritize transits over progressions—transits are secondary fine-tuning, not the main activators.
                    ❌ Mention transiting or progressed planets inside a house unless they are making aspects.
                    ❌ Interpret transits/progressions unless they aspect the ruler of the main house.
                    ❌ Discuss unrelated transits without linking them to the main house activation.
                    ❌ Predict outcomes—guide \(chartCake.name) to reflect on integration instead.
                    """

        
        

    }
  
    
    
    private func handleAgentResponse(_ response: String?, originalText: String) {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.messages.removeLast()
            self.chatTableView.reloadData()

            if let response = response {
                // Add response to UI
                self.messages.append((response, false))
                self.chatTableView.reloadData()
                self.scrollToBottom()

                // Save to local memory (optional)
                LilaMemoryManager.shared.saveMessage(role: "user", content: originalText)
                LilaMemoryManager.shared.saveMessage(role: "assistant", content: response)

                // Save to Firestore
                self.saveMessageToFirestore(role: "user", text: originalText)
                self.saveMessageToFirestore(role: "assistant", text: response)

            } else {
                let fallback = "❌ Something went wrong. Please try again."
                self.messages.append((fallback, false))
                self.chatTableView.reloadData()
                self.scrollToBottom()
            }
        }
    }

    private func saveMessageToFirestore(role: String, text: String) {
        guard
            let userId = Auth.auth().currentUser?.uid,
            let convoId = currentConversationId
        else { return }

        let db = Firestore.firestore()
        let messageData: [String: Any] = [
            "text": text,
            "isUser": role == "user",
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("users").document(userId)
            .collection("conversations").document(convoId)
            .collection("messages").addDocument(data: messageData)
    }


    // Helper function to generate synastry data including the strongest interaspects
    private func generateSynastryData(userChart: ChartCake, partnerChart: ChartCake) -> String {
        let userName = userChart.name ?? "User"
        let partnerName = partnerChart.name ?? "Partner"
        
        // Create Chart objects from ChartCakes
        let chart1 = Chart(date: userChart.natal.birthDate,
                           latitude: userChart.natal.latitude,
                           longitude: userChart.natal.longitude)
                          // Adjust as needed
        
        let chart2 = Chart(date: partnerChart.natal.birthDate,
                           latitude: partnerChart.natal.latitude,
                           longitude: partnerChart.natal.longitude)
                     
        
        // Create SynastryChart
        let synastryChart = SynastryChart(chart1: userChart.natal, chart2: partnerChart.natal, name1: userName, name2: partnerName)
        
        // Get user and partner planet coordinates
        let userPlanets = userChart.natal.planets
        let partnerPlanets = partnerChart.natal.planets
        
        // Convert to Coordinate arrays
        let userCoordinates = userPlanets.map { $0 }
        let partnerCoordinates = partnerPlanets.map { $0 }
        
        // Get all interaspects
        let interaspects = synastryChart.interAspects(rickysPlanets: userCoordinates,
                                                     linneasPlanets: partnerCoordinates,
                                                     name1: userName,
                                                     name2: partnerName)
        
        // Get aspect scores to find the strongest aspects
        let aspectScores = synastryChart.interchartAspectScores(aspects: interaspects, name1: userName, name2: partnerName)
        
        // Get the top 10 strongest aspects
        let topAspects = aspectScores.prefix(10)
        
        // Format the synastry data
        var synastryData = "TOP 10 STRONGEST INTERASPECTS:\n"
        
        for (aspect, score) in topAspects {
            synastryData += "• \(aspect.body1.body.keyName) (\(userName)) \(aspect.kind.description) \(aspect.body2.body.keyName) (\(partnerName)) - Orb: \(String(format: "%.1f", aspect.orbDelta))° - Strength: \(String(format: "%.1f", score))\n"
        }
        
        // Add information about planets in houses
        synastryData += "\n\(userName)'S PLANETS IN \(partnerName)'S HOUSES:\n"
        let userPlanetsInPartnerHouses = synastryChart.othersPlanetInHouses(using: partnerChart.natal.houseCusps, with: userCoordinates)
        
        for (houseNumber, planets) in userPlanetsInPartnerHouses.sorted(by: { $0.key < $1.key }) {
            synastryData += "House \(houseNumber): \(planets.map { $0.keyName }.joined(separator: ", "))\n"
        }
        
        synastryData += "\n\(partnerName)'S PLANETS IN \(userName)'S HOUSES:\n"
        let partnerPlanetsInUserHouses = synastryChart.othersPlanetInHouses(using: userChart.natal.houseCusps, with: partnerCoordinates)
        
        for (houseNumber, planets) in partnerPlanetsInUserHouses.sorted(by: { $0.key < $1.key }) {
            synastryData += "House \(houseNumber): \(planets.map { $0.keyName }.joined(separator: ", "))\n"
        }
        
        return synastryData
    }
    /**
     * Updated method to handle date selection for transit/progression readings
     */
    private func createTransitChart(for date: Date) -> ChartCake {
        let birthdate = chartCake.natal.birthDate,
            latitude = chartCake.natal.latitude,
            longitude = chartCake.natal.longitude

        let today = Date().adjust(for: .startOfDay)!
        let selectedDate = date.adjust(for: .startOfDay)!
        let isPastDate = selectedDate < today
        let isFutureDate = selectedDate > today

        // Calculate time difference for context
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: today, to: selectedDate)
        let yearsApart = abs(components.year ?? 0)
        let monthsApart = abs(components.month ?? 0)
        let daysApart = abs(components.day ?? 0)

        // Create transit chart with time difference context
        transitChartCake = ChartCake(
            birthDate: birthdate,
            latitude: latitude,
            longitude: longitude,
            transitDate: date
        )

        // ✅ Ensure the `.transits.transitDate` is also populated:
        transitChartCake?.transits.transitDate = date
print("Transit Date: \(transitChartCake?.transits.transitDate)")

        // Store time difference data in user defaults for the model
        let timeContext: [String: Any] = [
            "isPast": isPastDate,
            "isFuture": isFutureDate,
            "yearsApart": yearsApart,
            "monthsApart": monthsApart,
            "daysApart": daysApart,
            "selectedDate": selectedDate
        ]

        UserDefaults.standard.set(timeContext, forKey: "transitTimeContext")

        print("✅ Transit Chart Updated for: \(date), \(isPastDate ? "Past" : isFutureDate ? "Future" : "Present") date, \(yearsApart) years, \(monthsApart) months, \(daysApart) days apart")

        // Clear any partner chart when selecting a transit date
        otherChart = nil

        // Clear conversation history
        LilaMemoryManager.shared.clearConversationHistory()

        // Now re-prompt the agent with the updated chart and time context
        autoPromptForNewDateContext(isPast: isPastDate, isFuture: isFutureDate, selectedDate: date,yearsApart: yearsApart, monthsApart: monthsApart, daysApart: daysApart)
        return transitChartCake!
    }

    private func autoPromptForNewDateContext(isPast: Bool, isFuture: Bool, selectedDate: Date,
                                             yearsApart: Int, monthsApart: Int, daysApart: Int) {
        let formattedDate = DateFormatter.localizedString(from: selectedDate, dateStyle: .medium, timeStyle: .none)

        // Create user-visible prompt
        var prompt = "You've added new context:\n"
        prompt += "🔹 Selected a **\(isPast ? "past" : isFuture ? "future" : "current") date**: \(formattedDate).\n"

        // Add time difference context for user
        if yearsApart > 0 {
            prompt += "🕒 This is \(yearsApart) year\(yearsApart > 1 ? "s" : "") \(isPast ? "in the past" : "in the future").\n"
        } else if monthsApart > 0 {
            prompt += "🕒 This is \(monthsApart) month\(monthsApart > 1 ? "s" : "") \(isPast ? "in the past" : "in the future").\n"
        } else if daysApart > 0 {
            prompt += "🕒 This is \(daysApart) day\(daysApart > 1 ? "s" : "") \(isPast ? "in the past" : "in the future").\n"
        }

        // Add tailored questions based on the date context
        if isPast {
            prompt += "\n🕰️ What happened on \(formattedDate)?"
        } else if isFuture {
            prompt += "\n📅 What are you planning for \(formattedDate)?"
        } else {
            prompt += "\n👋 What's new these days??"
        }

        messages.append((prompt, false))
        chatTableView.reloadData()
        scrollToBottom()

        let age = calculateAgeString(from: chartCake.natal.birthDate, to: Date())

        // Create hidden context for the AI model with detailed transit/progression information
        guard let transitChart = transitChartCake else { return }


        // Create internal context with transit and progression data
        let internalContext = """
        READING TYPE: TRANSIT & PROGRESSION
        
        ⏳ TIME CONTEXT:
        - \(isPast ? "Past" : isFuture ? "Future" : "Present") date
        - \(yearsApart > 0 ? "\(yearsApart) years" : monthsApart > 0 ? "\(monthsApart) months" : "\(daysApart) days") \(isPast ? "ago" : "from now")
        


"""

        // Log the context to verify it's being created correctly
        print("📊 Sending context to model: \n\(internalContext)")

        // Store this context for the AI model to access
        LilaMemoryManager.shared.addInternalPrompt(internalContext)

        // Save context to UserDefaults as backup
        UserDefaults.standard.set(internalContext, forKey: "lastTransitContext")
    }

    private func formatHouseRulerships(for cake: ChartCake) -> String {
        (1...12).map { house in
            let rulers = cake.rulingBodies(for: house).map { $0.body.keyName }
            return "• \(house)th House: \(rulers.joined(separator: ", "))"
        }.joined(separator: "\n")
    }
    /**
     * Updated method to handle partner selection for synastry readings
     */
    private func setPartnerChart(_ chartEntity: ChartEntity) {
        guard let birthDate = chartEntity.birthDate else { return }
        
    let partnerChart = ChartCake(
            birthDate: birthDate,
            latitude: chartEntity.latitude,
            longitude: chartEntity.longitude,
            name: chartEntity.name
        )
        
        // Set partner chart
        self.otherChart = partnerChart
        
        // Clear any transit chart when selecting a partner
        self.transitChartCake = nil
        
        print("✅ Partner Chart Set: \(partnerChart.name ?? "Unknown")")
        
        // Save partner reference using optional binding correctly
        if let chartID = chartCake?.id.uuidString {
            let partnerID = chartEntity.objectID.uriRepresentation().absoluteString
            saveRecentPartner(myID: chartID, partnerID: partnerID)
        }
        
        // Auto-prompt the user
        autoPromptForNewPartnerContext()
    }

    // Helper method to save recent partners
    private func saveRecentPartner(myID: String, partnerID: String) {
        let key = "recentPartners_\(myID)"
        var recentPartners = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        // Add to beginning of list if not already there, or move to beginning if already in list
        if let existingIndex = recentPartners.firstIndex(of: partnerID) {
            recentPartners.remove(at: existingIndex)
        }
        
        recentPartners.insert(partnerID, at: 0)
        
        // Keep only the 5 most recent partners
        if recentPartners.count > 5 {
            recentPartners = Array(recentPartners.prefix(5))
        }
        
        UserDefaults.standard.set(recentPartners, forKey: key)
        print("✅ Saved recent partner reference")
    }
    /**
     * Auto-prompt specifically for synastry readings
     */
    private func autoPromptForNewPartnerContext() {
        guard let partner = otherChart, let user = chartCake else { return }

        let userName = user.name ?? "User"
        let partnerName = partner.name ?? "Partner"

        // ✅ Show this to user
        let userPrompt = """
        You've added new context:
        🔹 Partner Chart: \(partnerName)

        First, could you tell me about the nature of your relationship with \(partnerName)?
        (For example: romantic partner, spouse, parent/child, friend, colleague, etc.)
        """

        messages.append((userPrompt, false))
        chatTableView.reloadData()
        scrollToBottom()

        // ❌ Don't show this to user — just send to model
        let internalContext = """
        - \(partnerName) is \(userName)'s [RELATIONSHIP TYPE] (please clarify)
        - \(partnerName) is NOT present in this conversation
        - \(partnerName) should ALWAYS be referred to in the third person
        - IMPORTANT: You are talking TO \(userName) ABOUT their relationship WITH \(partnerName)
        - NEVER assume \(userName) is asking questions on behalf of \(partnerName)
        - NEVER confuse the roles – always remember that \(userName) is asking about their [RELATIONSHIP TYPE] named \(partnerName)
        """

        LilaMemoryManager.shared.addInternalPrompt(internalContext)
    }




    /**
     * Auto-prompt specifically for transit/progression readings
     */
    private func autoPromptForNewDateContext(isPast: Bool, isFuture: Bool, selectedDate: Date) {
        let formattedDate = DateFormatter.localizedString(from: selectedDate, dateStyle: .medium, timeStyle: .none)

        var prompt = "You've added new context:\n"
        prompt += "🔹 Selected a **\(isPast ? "past" : isFuture ? "future" : "current") date**: \(formattedDate).\n"

        // Add tailored questions based on the date context
        if isPast {
            prompt += "\n🕰️ What happened on \(formattedDate)?"
        } else if isFuture {
            prompt += "\n📅 What are you planning for \(formattedDate)?"
        } else {
            prompt += "\n👋 What's new these days??"
        }

        messages.append((prompt, false))
        chatTableView.reloadData()
        scrollToBottom()
    }
}

// MARK: - TableView DataSource
extension MyAgentChatController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ChatCell")

        let (message, isUser) = messages[indexPath.row]

        cell.textLabel?.text = message
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.textAlignment = isUser ? .right : .left
        cell.backgroundColor = isUser ? UIColor.systemBlue.withAlphaComponent(0.1) : UIColor.systemGray6
        cell.textLabel?.textColor = isUser ? .black : .darkGray
        cell.layer.cornerRadius = 12
        cell.clipsToBounds = true

        return cell
    }
}

// MARK: UITableViewDelegate
extension MyAgentChatController: UITableViewDelegate {
    enum ClipboardError: Error {
        case failedToWrite
        case invalidContent
    }

    func writeToClipboard(_ text: String) throws {
        guard !text.isEmpty else {
            throw ClipboardError.invalidContent
        }

        UIPasteboard.general.string = text
    }

    func readFromClipboard() throws -> String {
        guard let content = UIPasteboard.general.string else {
            throw ClipboardError.failedToWrite
        }
        return content
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]

        do {
            try writeToClipboard(message.0)
        }
        catch let error {
            switch error {
            case let clipboardError as ClipboardError:
                switch clipboardError {
                case .invalidContent:
                    print("Cannot write nil or empty content")
                case .failedToWrite:
                    print("General clipboard write failure")
                }
            default:
                print("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension MyAgentChatController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Calculate the size that fits the content
        let fixedWidth = textView.frame.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))

        // Define minimum and maximum heights
        let minHeight: CGFloat = 40
        let maxHeight: CGFloat = 120

        // Calculate new height within bounds
        let newHeight = min(max(newSize.height, minHeight), maxHeight)

        // Only update if height changed
        if textView.frame.height != newHeight {
            // Find the height constraint
            textView.constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    // Animate the height change
                    UIView.animate(withDuration: 0.1) {
                        constraint.constant = newHeight
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }

        // Enable/disable scrolling based on content size
        textView.isScrollEnabled = newSize.height > maxHeight
    }
}
// MARK: - PartnerSelectionDelegate
extension MyAgentChatController: PartnerSelectionDelegate {
    func didSelectPartner(chartCake: ChartCake) {
        self.otherChart = chartCake
        print("✅ Selected Partner: \(chartCake.name ?? "Unknown")")
        autoPromptForNewPartnerContext()
    }
}

// MARK: - Forecast Integration

extension MyAgentChatController {
    @objc func showForecastTapped() {
        guard let chartCake = chartCake else {
            addSystemMessage("⚠️ No chart available to generate forecast.")
            return
        }
        
        let forecastVC = ForecastViewController(chartCake: chartCake)
        forecastVC.chartCake = chartCake
        forecastVC.delegate = self
        
        let navController = UINavigationController(rootViewController: forecastVC)
        present(navController, animated: true)
        
        // Log analytics event
        Analytics.logEvent("forecast_viewed", parameters: nil)
    }
    

  
}


// MARK: - AIServiceDelegate
extension MyAgentChatController: AIServiceDelegate {
    func didSelectAIService() {
        // Update the UI to reflect the new AI service
        updateAIServiceIndicator()

        // Add a message to inform the user about the change
        let selectedServiceIndex = UserDefaults.standard.integer(forKey: "selectedAIService")
        let serviceName: String

        switch selectedServiceIndex {
        case 0:
            serviceName = "OpenAI"
        case 1:
            serviceName = "Claude"
        case 2:
            serviceName = "HuggingFace"
        default:
            serviceName = "OpenAI"
        }

        let message = "🤖 AI Service changed to \(serviceName). How can I help you with your chart?"
        messages.append((message, false))
        chatTableView.reloadData()
        scrollToBottom()
    }
}
//
//  PartnerSelection.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.
protocol PartnerSelectionDelegate: AnyObject {
    func didSelectPartner(chartCake: ChartCake)
}

class PartnerSelectionPopoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    weak var delegate: PartnerSelectionDelegate?
    var currentChartCake: ChartCake?

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search partners..."
        return searchBar
    }()

    private let tableView = UITableView()
    private var charts: [ChartEntity] = []
    private var filteredCharts: [ChartEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCharts()
        searchBar.delegate = self
    }

    private func setupUI() {
        view.backgroundColor = .white
        preferredContentSize = CGSize(width: 300, height: 400)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChartCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }

    private func fetchCharts() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<ChartEntity>(entityName: "ChartEntity")

        do {
            let fetchedCharts = try context.fetch(fetchRequest)

            var uniqueCharts: [ChartEntity] = []
            var seenCharts = Set<String>()

            for chart in fetchedCharts {
                guard let name = chart.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { continue }

                let identifier = "\(name)_\(chart.birthDate?.timeIntervalSince1970 ?? 0)_\(chart.latitude)_\(chart.longitude)"

                // Skip if this is the current chart
                if let current = currentChartCake,
                   chart.birthDate == current.natal.birthDate &&
                   chart.latitude == current.natal.latitude &&
                   chart.longitude == current.natal.longitude {
                    continue
                }

                if !seenCharts.contains(identifier) {
                    seenCharts.insert(identifier)
                    uniqueCharts.append(chart)
                }
            }

            charts = uniqueCharts
            filteredCharts = charts
            tableView.reloadData()
        } catch {
            print("❌ Failed to fetch charts: \(error.localizedDescription)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCharts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Use .subtitle style to show name and birthdate
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ChartCell")
        let chart = filteredCharts[indexPath.row]

        cell.textLabel?.text = chart.name

        if let date = chart.birthDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            cell.detailTextLabel?.text = formatter.string(from: date)
        } else {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedChart = filteredCharts[indexPath.row]

        guard let birthDate = selectedChart.birthDate else { return }
        let latitude = selectedChart.latitude
        let longitude = selectedChart.longitude
        let name = selectedChart.name

        let chartCake = ChartCake(birthDate: birthDate, latitude: latitude, longitude: longitude, name: name)

        // Animate dismiss before sending delegate callback
        dismiss(animated: true) {
            self.delegate?.didSelectPartner(chartCake: chartCake)
        }
    }

    // MARK: - Search Functionality
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredCharts = charts
        } else {
            filteredCharts = charts.filter {
                $0.name?.lowercased().contains(searchText.lowercased()) == true
            }
        }
        tableView.reloadData()
    }
}
