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
        setupKeyboardNotifications()
        setupUI()
        setupNavigationBar()
        startNewConversation()
        print("💬 AgentChat loaded with chartCake: \(chartCake?.name ?? "nil")")
           
           // Load previous conversations instead of just adding greeting message
          
        if let uid = Auth.auth().currentUser?.uid {
            ChartContextManager.shared.fetchChartSummary(for: uid) { [weak self] summary in
                guard let self = self, let summary = summary else { return }
                self.chartSummaryContext = generateChartContextPrompt(from: summary)
            }
        }

        Analytics.logEvent("specialFeatures_tabeView_viewed", parameters: nil)

        // Check if user is admin using your existing method
        isAdminUser { [weak self] isAdmin in
            guard let self = self else { return }
            self.isAdmin = isAdmin
            if isAdmin {
                self.addMigrationButton()
            }
        }

        // Initial greeting message
        let greetingMessage = """
        🌟 Welcome to Ask Lila! I'm Lila, your AI astrology partner.

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
    private func addMigrationButton() {
        let migrateIcon = UIImage(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
        let migrateButton = UIBarButtonItem(image: migrateIcon, style: .plain, target: self, action: #selector(showMigrationVC))
        navigationItem.rightBarButtonItems?.append(migrateButton)
    }

    @objc private func showMigrationVC() {
        let migrationVC = DataMigrationViewController()
        navigationController?.pushViewController(migrationVC, animated: true)
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
        // Existing code for your other buttons
        let calendarIcon = UIImage(systemName: "calendar")
        let personIcon = UIImage(systemName: "person.2")
        let aiIcon = UIImage(systemName: "brain.head.profile") // AI service icon
        let gearIcon = UIImage(systemName: "gearshape") // Settings/edit icon
        let storyIcon = UIImage(systemName: "book.pages") // Story icon
        let statsIcon = UIImage(systemName: "chart.bar.doc.horizontal") // Astro-stats icon
        
        let historyIcon = UIImage(systemName: "clock.arrow.circlepath")
        let historyButton = UIBarButtonItem(image: historyIcon, style: .plain, target: self, action: #selector(showConversationHistory))
        
  
        let selectDateButton = UIBarButtonItem(image: calendarIcon, style: .plain, target: self, action: #selector(selectDateTapped))
        let addPartnerButton = UIBarButtonItem(image: personIcon, style: .plain, target: self, action: #selector(selectPartnerTapped))
        let selectAIServiceButton = UIBarButtonItem(image: aiIcon, style: .plain, target: self, action: #selector(selectAIServiceTapped))
        let editChartButton = UIBarButtonItem(image: gearIcon, style: .plain, target: self, action: #selector(editChartTapped))
        let showStoryButton = UIBarButtonItem(image: storyIcon, style: .plain, target: self, action: #selector(showSouthNodeStoryTapped))
       let showStatsButton = UIBarButtonItem(image: statsIcon, style: .plain, target: self, action: #selector(showStatsTapped))

        // Add all buttons to the right side of the navigation bar
        navigationItem.rightBarButtonItems = [addPartnerButton, selectDateButton,  showStoryButton]
        navigationItem.leftBarButtonItems = [editChartButton, selectAIServiceButton, historyButton,showStatsButton]
        // Add badge or indicator showing current AI service
        updateAIServiceIndicator()
    }

    
    @objc private func showConversationHistory() {
        // Present the AI service selector
        let historyVC = ConversationHistoryViewController()
  
        let navController = UINavigationController(rootViewController: historyVC)
        present(navController, animated: true)
    }

    // MARK: - UI Setup
    // First, update the UI setup to add an input container view
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
            self.chatTableView.contentInset.bottom = 0
            self.chatTableView.scrollIndicatorInsets.bottom = 0
            self.scrollToBottom()
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

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let animationOptions = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: animationOptions) {
            // Reset the constraint
            self.view.constraints.first(where: { $0.firstAttribute == .bottom && $0.firstItem is UIView })?.constant = 0

            self.view.layoutIfNeeded()
            self.chatTableView.contentInset.bottom = 0
            self.chatTableView.scrollIndicatorInsets.bottom = 0
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
        print("Edit button tapped") // For debugging
        
        // Method 1: Get the SceneDelegate via the UIWindowScene
        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate {
            print("Found SceneDelegate via windowScene")
            sceneDelegate.showEditChartScreen()
            return
        }
        
        // Method 2: Alternative approach if Method 1 fails
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            print("Found SceneDelegate via UIApplication")
            sceneDelegate.showEditChartScreen()
            return
        }
        
        print("Could not find SceneDelegate")
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
        🌟 Welcome to Ask Lila! I'm Lila, your AI astrology partner.

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
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: 50, to: Date()) // Future limit
        datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) // Past limit
        datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) // Past limit

        let alert = UIAlertController(title: "Select a Date", message: nil, preferredStyle: .actionSheet)

        // Ensure proper popover presentation for iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        alert.view.addSubview(datePicker)

        let heightConstraint = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        alert.view.addConstraint(heightConstraint)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.transitChartCake = nil
            self.createTransitChart(for: datePicker.date)
        }))

        present(alert, animated: true)
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



    
    
    @objc private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty else { return }

        messages.append((text, true))
        chatTableView.reloadData()
        scrollToBottom()
        messageInputField.text = ""

        // Add a thoughtful consultation message
        let loadingMessage = contextAwareLoadingMessage()
        messages.append((loadingMessage, false))
        chatTableView.reloadData()
        scrollToBottom()

        // Show the loading indicator
        loadingIndicator.startAnimating()

        // Use transitChartCake if available, otherwise use the regular chart
        let chartToUse = transitChartCake ?? chartCake

        // Determine reading type based on available context
        let readingType: String
        if otherChart != nil {
            readingType = "SYNASTRY/RELATIONSHIP"
        } else if transitChartCake != nil {
            readingType = "TRANSIT & PROGRESSION"
        } else {
            readingType = "NATAL CHART"
        }

        // Log the reading type
        print("🔍 Performing \(readingType) reading")
        var fullPrompt = ""

        if let context = chartSummaryContext {
            fullPrompt += """
            🧠 CHART MEMORY CONTEXT:
            \(context)

            """
        }

      

        // Format the prompt to be more explicit about the context
        let formattedPrompt = """
        READING TYPE: \(readingType)
        
        
        
        USER QUESTION: \(text)
        """
        fullPrompt += formattedPrompt
        // Send to Lila agent
        LilaAgentManager.shared.sendMessageToAgent(
            prompt: formattedPrompt,
            userChart: chartToUse,
            otherChart: otherChart
        ) { [weak self] response in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Stop the loading indicator
                self.loadingIndicator.stopAnimating()

                // Remove the loading message before adding the real response
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
    private func createTransitChart(for date: Date) {
        let birthdate = chartCake.natal.birthDate,
            latitude = chartCake.natal.latitude,
            longitude = chartCake.natal.longitude

        let today = Date().adjust(for: .startOfDay)!
        let selectedDate = date.adjust(for: .startOfDay)!
        let isPastDate = selectedDate < today
        let isFutureDate = selectedDate > today

        // Create transit chart
        transitChartCake = ChartCake(
            birthDate: birthdate,
            latitude: latitude,
            longitude: longitude,
            transitDate: date
        )

        print("✅ Transit Chart Updated for: \(date)")

        // Clear any partner chart when selecting a transit date
        // This ensures we don't mix transit and synastry readings
        otherChart = nil

        // Clear conversation history
        LilaMemoryManager.shared.clearConversationHistory()

        // Now re-prompt the agent with the updated chart
        autoPromptForNewDateContext(isPast: isPastDate, isFuture: isFutureDate, selectedDate: date)
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
        let maxHeight: CGFloat = 120
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)

        textView.isScrollEnabled = estimatedSize.height > maxHeight
        textView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = min(estimatedSize.height, maxHeight)
            }
        }
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
