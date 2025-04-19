// MARK: - ForecastViewController

import UIKit
import SwiftEphemeris


struct Transit: Identifiable {
    let id = UUID()
    let planetA: String
    let aspect: String
    let planetB: String
    let startDate: Date
    let endDate: Date
}
enum Elements: String, CaseIterable {
    case fire, earth, air, water
}
struct Horoscope {
    let category: String
    let interpretation: String
}

struct ElementalBreakdown {
    let fire: Double
    let earth: Double
    let air: Double
    let water: Double
}

class ForecastViewController: UIViewController {
    // MARK: - Properties
    var chartCake: ChartCake!
    var delegate: MyAgentChatController?
    
    private let segmentedControl = UISegmentedControl(items: ["Daily", "Weekly", "Monthly", "Yearly"])
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Chat UI elements
    private let chatInputView = UIView()
    private let messageInputField = UITextView()
    private let sendButton = UIButton(type: .system)
    
    private let viewModel: TransitViewModel
    private var messages: [(String, Bool)] = [] // (Message, isUser)
    
    // Element mapping for elemental breakdown
    private let elementSigns: [Elements: [Zodiac]] = [
        .fire: [.aries, .leo, .sagittarius],
        .earth: [.taurus, .virgo, .capricorn],
        .air: [.gemini, .libra, .aquarius],
        .water: [.cancer, .scorpio, .pisces]
    ]
    
    // MARK: - Initialization
    init(chartCake: ChartCake) {
        self.chartCake = chartCake
        self.viewModel = TransitViewModel(chartCake: chartCake)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        
        // Start with daily forecast
        segmentedControl.selectedSegmentIndex = 0
        segmentChanged(segmentedControl)
        
        // Add initial greeting
        let greeting = "You can ask me questions about this forecast or tap 'Use in Chat' to share it with your main conversation."
        messages.append((greeting, false))
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Forecast"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Use in Chat", style: .plain, target: self, action: #selector(useInChatTapped))
        
        // Set up segmented control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Set up table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TransitCell.self, forCellReuseIdentifier: "TransitCell")
        tableView.register(InterpretationCell.self, forCellReuseIdentifier: "InterpretationCell")
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        view.addSubview(tableView)
        
        // Set up loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Set up chat input view
        chatInputView.backgroundColor = .systemBackground
        chatInputView.translatesAutoresizingMaskIntoConstraints = false
        chatInputView.layer.borderColor = UIColor.systemGray5.cgColor
        chatInputView.layer.borderWidth = 1
        view.addSubview(chatInputView)
        
        // Set up message input field
        messageInputField.font = UIFont.systemFont(ofSize: 16)
        messageInputField.isScrollEnabled = false
        messageInputField.layer.cornerRadius = 18
        messageInputField.layer.borderColor = UIColor.systemGray3.cgColor
        messageInputField.layer.borderWidth = 1
        messageInputField.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        chatInputView.addSubview(messageInputField)
        
        // Set up send button
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        sendButton.addTarget(self, action: #selector(sendMessageTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        chatInputView.addSubview(sendButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            chatInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            chatInputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            messageInputField.leadingAnchor.constraint(equalTo: chatInputView.leadingAnchor, constant: 16),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageInputField.topAnchor.constraint(equalTo: chatInputView.topAnchor, constant: 8),
            messageInputField.bottomAnchor.constraint(equalTo: chatInputView.bottomAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: chatInputView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: chatInputView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chatInputView.topAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Set up binding to viewModel
        viewModel.didUpdateTransits = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.didUpdateHoroscope = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }

        
        viewModel.didChangeLoadingState = { [weak self] isLoading in
            if isLoading {
                self?.loadingIndicator.startAnimating()
            } else {
                self?.loadingIndicator.stopAnimating()
            }
        }
    }
    
    private func setupDelegates() {
        tableView.dataSource = self
        tableView.delegate = self
        messageInputField.delegate = self
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let category = getCategory(from: sender.selectedSegmentIndex)
        
        // Calculate elemental breakdown
        let elementPercentages = calculateElementalBreakdown(signScores: chartCake.signScoresSN)
        let userElements = ElementalBreakdown(
            fire: elementPercentages[.fire] ?? 0,
            earth: elementPercentages[.earth] ?? 0,
            air: elementPercentages[.air] ?? 0,
            water: elementPercentages[.water] ?? 0
        )
        
        // Load data for selected category
        viewModel.loadData(for: category, userElements: userElements)
        
        // Reset chat messages when changing periods
        messages = [(messages.first?.0 ?? "How can I help you understand this forecast?", false)]
        tableView.reloadData()
    }
    
    @objc private func useInChatTapped() {
        guard let horoscope = viewModel.horoscope else { return }
        let category = getCategory(from: segmentedControl.selectedSegmentIndex)
        
        // Format the forecast data to pass to the chat
        let forecastData = formatForecastData(category: category, transits: viewModel.transits, interpretation: horoscope.interpretation)
        delegate?.addSystemMessage(forecastData)
        
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func sendMessageTapped() {
        guard let text = messageInputField.text, !text.isEmpty else { return }
        
        // Add user message to the UI
        messages.append((text, true))
        tableView.reloadData()
        scrollToBottom()
        messageInputField.text = ""
        
        // Show loading indicator
        loadingIndicator.startAnimating()
        
        // Get current forecast data
        let category = getCategory(from: segmentedControl.selectedSegmentIndex)
        
        // Create context for the AI model with forecast data
        var forecastContext = """
        READING TYPE: FORECAST
        
        The user is looking at their \(category.uppercased()) FORECAST which contains:
        
        TRANSITS:
        \(viewModel.transits.prefix(5).joined(separator: "\n"))
        
        INTERPRETATION:
        \(viewModel.horoscope?.interpretation ?? "Not available")
        
        USER QUESTION: \(text)
        """
        
        // Send to AI service with the right chart context
        LilaAgentManager.shared.sendMessageToAgent(
            prompt: forecastContext,
            userChart: chartCake,
            otherChart: nil
        ) { [weak self] response in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if let response = response {
                    self.messages.append((response, false))
                } else {
                    self.messages.append(("I'm sorry, I encountered an error processing your request.", false))
                }
                
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    private func getCategory(from index: Int) -> String {
        switch index {
        case 0: return "daily"
        case 1: return "weekly"
        case 2: return "monthly"
        case 3: return "yearly"
        default: return "daily"
        }
    }
    
    private func scrollToBottom() {
        let lastSection = tableView.numberOfSections - 1
        guard lastSection >= 0 else { return }
        
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // MARK: - Helper Methods
    func calculateElementalBreakdown(signScores: [Zodiac: Double]) -> [Elements: Double] {
        var elementScores: [Elements: Double] = [.fire: 0, .earth: 0, .air: 0, .water: 0]
        
        // Aggregate scores per element
        for (element, signs) in elementSigns {
            for sign in signs {
                if let score = signScores[sign] {
                    elementScores[element, default: 0] += score
                }
            }
        }
        
        // Normalize to percentages
        let totalScore = elementScores.values.reduce(0, +)
        guard totalScore > 0 else { return elementScores } // Prevent division by zero
        
        for element in Elements.allCases {
            elementScores[element] = (elementScores[element] ?? 0) / totalScore * 100
        }
        
        return elementScores
    }
    
    private func formatForecastData(category: String, transits: [String], interpretation: String) -> String {
        let timeframe: String
        switch category {
        case "daily": timeframe = "Daily"
        case "weekly": timeframe = "Weekly"
        case "monthly": timeframe = "Monthly"
        case "yearly": timeframe = "Yearly"
        default: timeframe = "Custom"
        }
        
        // Limit transit count for readability
        let topTransits = transits.prefix(7)
        let transitList = topTransits.isEmpty ?
            "No significant transits for this period." :
            topTransits.joined(separator: "\n")
        
        return """
        ✨ \(timeframe) Forecast:
        
        TRANSITS:
        \(transitList)
        
        INTERPRETATION:
        \(interpretation)
        """
    }
    
    // MARK: - Custom Cell Classes
    class TransitCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)
            textLabel?.numberOfLines = 0
            textLabel?.font = UIFont.systemFont(ofSize: 15)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class InterpretationCell: UITableViewCell {
        let textView = UITextView()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)

            // Use UITextView instead of UILabel for better text rendering
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.font = UIFont.systemFont(ofSize: 16)
            textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            textView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(textView)

            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(with text: String) {
            textView.text = text
        }
    }
    class MessageCell: UITableViewCell {
        let messageLabel = UILabel()
        let bubbleView = UIView()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)
            
            selectionStyle = .none
            backgroundColor = .clear
            
            bubbleView.layer.cornerRadius = 16
            bubbleView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(bubbleView)
            
            messageLabel.numberOfLines = 0
            messageLabel.font = UIFont.systemFont(ofSize: 16)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            bubbleView.addSubview(messageLabel)
            
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
                
                bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
                bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configure(message: String, isUser: Bool) {
            messageLabel.text = message
            
            if isUser {
                bubbleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
                messageLabel.textColor = .white
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60).isActive = true
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
            } else {
                bubbleView.backgroundColor = UIColor.systemGray5
                messageLabel.textColor = .label
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12).isActive = true
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60).isActive = true
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ForecastViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.isLoading ? 0 : 3  // Transits, Interpretation, Chat
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return viewModel.transits.isEmpty ? 1 : min(viewModel.transits.count, 10) // Limit to top 10 transits
        case 1: return viewModel.horoscope != nil ? 1 : 0
        case 2: return messages.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Transits"
        case 1: return "Interpretation"
        case 2: return messages.isEmpty ? nil : "Chat"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransitCell", for: indexPath) as! TransitCell
            
            if viewModel.transits.isEmpty {
                cell.textLabel?.text = "No transits available."
                cell.textLabel?.textColor = .gray
            } else {
                cell.textLabel?.text = viewModel.transits[indexPath.row]
                cell.textLabel?.textColor = .label
            }
            
            return cell
            
        case 1:
              let cell = tableView.dequeueReusableCell(withIdentifier: "InterpretationCell", for: indexPath) as! InterpretationCell

              if let interpretation = viewModel.horoscope?.interpretation {
                  print("🔍 Setting interpretation to cell: \(interpretation.prefix(50))...")
                  cell.configure(with: interpretation)
              } else {
                  print("⚠️ No interpretation available")
                  cell.configure(with: "Interpretation not available")
              }

              return cell


        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            let (message, isUser) = messages[indexPath.row]
            cell.configure(message: message, isUser: isUser)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension ForecastViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextViewDelegate
extension ForecastViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        // Adjust the height of the input container
        if let heightConstraint = chatInputView.constraints.first(where: { $0.firstAttribute == .height }) {
            let newHeight = max(60, min(estimatedSize.height + 16, 120))
            if heightConstraint.constant != newHeight {
                heightConstraint.constant = newHeight
                UIView.animate(withDuration: 0.1) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
}
// MARK: - Updated TransitViewModel
class TransitViewModel: ObservableObject {
    var transits: [String] = [] // Array of formatted transit descriptions
    var horoscope: Horoscope?
    var isLoading: Bool = false {
        didSet {
            didChangeLoadingState?(isLoading)
        }
    }

    // Callbacks for UI updates
    var didUpdateTransits: (() -> Void)?
    var didUpdateHoroscope: (() -> Void)?
    var didChangeLoadingState: ((Bool) -> Void)?

    private var chartCake: ChartCake?

    // MARK: - Initializer
    init(chartCake: ChartCake?) {
        self.chartCake = chartCake
    }

    /// Load data for the specified category and user elements
    func loadData(for category: String, userElements: ElementalBreakdown) {
        isLoading = true
        let now = Date()
        let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: now)!
        let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        
        guard let chartCake = chartCake else {
            print("Error: chartCake is not initialized.")
            isLoading = false
            return
        }
        
        // Fetch natal planets
        let natalPlanets = chartCake.natal.rickysBodies

        // Prepare filtered transits based on category
        var filteredTransits: [String] = []
        switch category {
        case "daily":
            filteredTransits = fetchDailyTransits()
        case "weekly":
            filteredTransits = fetchTransits(
                for: natalPlanets,
                startDate: now,
                endDate: oneWeekLater,
                orb: 1.5
            )
        case "monthly":
            // For monthly, include progressions
            let transits = fetchTransits(
                for: natalPlanets,
                startDate: now,
                endDate: oneMonthLater,
                orb: 2.0
            )
            let progressions = fetchProgressions(for: natalPlanets, endDate: oneMonthLater)
            filteredTransits = transits + progressions
        case "yearly":
            // For yearly, include progressions and solar arcs
            let transits = fetchTransits(
                for: natalPlanets,
                startDate: now,
                endDate: oneYearLater,
                orb: 3.0
            )
            let progressions = fetchProgressions(for: natalPlanets, endDate: oneYearLater)
            let solarArcs = fetchSolarArcs(for: natalPlanets, endDate: oneYearLater)
            filteredTransits = transits + progressions + solarArcs
        default:
            break
        }

        self.transits = filteredTransits
        didUpdateTransits?()

        // Format transit descriptions for AI
        let transitDescriptions = filteredTransits.map { formatTransitDescription($0) }

        // Send to AI for horoscope generation
        fetchPersonalizedHoroscope(for: category, elements: userElements, transits: transitDescriptions) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let interpretation):
                    self.horoscope = Horoscope(category: category, interpretation: interpretation)
                    print("✅ Received horoscope interpretation: \(interpretation.prefix(100))...") // Debug log
                    self.didUpdateHoroscope?()
                case .failure(let error):
                    print("Error fetching horoscope: \(error.localizedDescription)")
                }
                self.isLoading = false
            }
        }
    }
    // MARK: - Progression and Solar Arc Methods
    
    /// Fetch progressions for a specified time period
    private func fetchProgressions(for natalPlanets: [Coordinate], endDate: Date) -> [String] {
        guard let chartCake = chartCake else { return [] }
        
        // Get progressed planets
        let progressedPlanets = chartCake.major.planets
        
        var progressions: [String] = []
        
        // Check aspects between progressed and natal planets
        for progPlanet in progressedPlanets {
            for natalPlanet in natalPlanets {
//                if let aspect = chartCake.major.aspectBetween(progPlanet, natalPlanet, orb: 1.0) {
//                    let aspectString = "Progressed \(progPlanet.body.keyName) \(aspect.kind.description) natal \(natalPlanet.body.keyName)"
//                    progressions.append(aspectString)
//                }
            }
            
            // Also include sign changes
            let natalEquivalent = natalPlanets.first(where: { $0.body == progPlanet.body })
            if let natalEquivalent = natalEquivalent, natalEquivalent.sign != progPlanet.sign {
                let signChangeString = "Progressed \(progPlanet.body.keyName) has moved from \(natalEquivalent.sign.keyName) to \(progPlanet.sign.keyName)"
                progressions.append(signChangeString)
            }
        }
        
        return progressions
    }
    
    /// Fetch solar arcs for a specified time period
    private func fetchSolarArcs(for natalPlanets: [Coordinate], endDate: Date) -> [String] {
        guard let chartCake = chartCake else { return [] }
        
        // Calculate age for solar arc
        let ageComponents = Calendar.current.dateComponents([.year], from: chartCake.natal.birthDate, to: endDate)
        let ageInYears = Double(ageComponents.year ?? 0)
        
        // Each year = roughly 1 degree of solar arc
        let solarArcDegrees = ageInYears
        
        var solarArcs: [String] = []
        
        // Check aspects by solar arc
        for natalPlanet in natalPlanets {
            // Skip points like ascendant for simplicity
            if !["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune", "pluto"].contains(natalPlanet.body.keyName.lowercased()) {
                continue
            }
            
            // Project the planet forward by solar arc
            let projectedLongitude = natalPlanet.longitude + solarArcDegrees
            
            // Check aspects to natal planets
            for targetPlanet in natalPlanets {
                // Skip self-aspects
                if natalPlanet.body == targetPlanet.body { continue }
                
                // Check for major aspects with tight orb
                if checkForAspect(longitude1: projectedLongitude, longitude2: targetPlanet.longitude, aspectType: 0, orb: 1.0) {
                    solarArcs.append("Solar Arc \(natalPlanet.body.keyName) conjunct natal \(targetPlanet.body.keyName)")
                } else if checkForAspect(longitude1: projectedLongitude, longitude2: targetPlanet.longitude, aspectType: 180, orb: 1.0) {
                    solarArcs.append("Solar Arc \(natalPlanet.body.keyName) opposite natal \(targetPlanet.body.keyName)")
                } else if checkForAspect(longitude1: projectedLongitude, longitude2: targetPlanet.longitude, aspectType: 90, orb: 1.0) {
                    solarArcs.append("Solar Arc \(natalPlanet.body.keyName) square natal \(targetPlanet.body.keyName)")
                } else if checkForAspect(longitude1: projectedLongitude, longitude2: targetPlanet.longitude, aspectType: 120, orb: 1.0) {
                    solarArcs.append("Solar Arc \(natalPlanet.body.keyName) trine natal \(targetPlanet.body.keyName)")
                }
            }
        }
        
        return solarArcs
    }
    
    /// Helper method to check for aspects
    private func checkForAspect(longitude1: Double, longitude2: Double, aspectType: Double, orb: Double) -> Bool {
        let diff = abs(longitude1 - longitude2).truncatingRemainder(dividingBy: 360)
        let aspectDiff = min(diff, 360 - diff)
        return abs(aspectDiff - aspectType) <= orb
    }

    // MARK: - Existing Methods
    
    private func fetchTransits(for natalPlanets: [Coordinate], startDate: Date, endDate: Date, orb: Double) -> [String] {
            guard let chartCake = chartCake else { return [] }
            
            return natalPlanets.flatMap { planet in
                chartCake.natal.findTransitsStrings(
                    between: planet.body,
                    natalPlanet: planet,
                    orb: orb,
                    aspectTypes: Kind.primary,
                    startDate: startDate,
                    endDate: endDate
                )
            }
        }

        private func fetchDailyTransits() -> [String] {
            guard let chartCake = chartCake else { return [] }
            
            let allAspectScores = chartCake.allCelestialAspectScoresByAspect()
            return [
                chartCake.filterAndFormat(by: Planet.sun.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.moon.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.mercury.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.venus.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.mars.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.jupiter.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.saturn.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.uranus.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.neptune.celestialObject, aspectsScores: allAspectScores, includeParallel: true),
                chartCake.filterAndFormat(by: Planet.pluto.celestialObject, aspectsScores: allAspectScores, includeParallel: true)
            ].flatMap { $0 }
        }

        private func formatTransitDescription(_ transit: String) -> String {
            return "Transit: \(transit)"
        }

        // MARK: - Fetch Personalized Horoscope
        func fetchPersonalizedHoroscope(for category: String, elements: ElementalBreakdown, transits: [String], completion: @escaping (Result<String, Error>) -> Void) {
            // Create time-specific guidance based on forecast period
            let timeGuidance: String
            switch category {
            case "daily":
                timeGuidance = """
                This is a DAILY forecast, which should focus on:
                - Immediate planetary influences affecting the person today
                - Specific advice for navigating today's energies
                - Practical guidance for using today's influences constructively
                """
            case "weekly":
                timeGuidance = """
                This is a WEEKLY forecast, which should focus on:
                - Short-term transit patterns over the next 7 days
                - How energies will shift and flow throughout the week
                - Areas of focus and attention for the coming days
                - Strategic timing advice for the week ahead
                """
            case "monthly":
                timeGuidance = """
                This is a MONTHLY forecast, which should focus on:
                - Both transits and progressions (marked in the data)
                - Emerging themes and developments over the next 30 days
                - Areas of life experiencing significant evolutionary pressure
                - How to prepare for and work with longer-term influences
                - Balancing immediate needs with developing trends
                """
            case "yearly":
                timeGuidance = """
                This is a YEARLY forecast, which should focus on:
                - Major life themes and evolutionary opportunities
                - Significant transits, progressions, and solar arcs (all marked in the data)
                - Long-term growth cycles and developmental stages
                - Strategic planning for the year ahead
                - How different life areas will be activated throughout the year
                - Primary evolutionary lessons and soul growth opportunities
                """
            default:
                timeGuidance = ""
            }
            
            // Create system prompt for AI
            let systemPrompt = """
            You are an expert evolutionary astrologer generating a personalized \(category) horoscope.
            
            ELEMENTAL PROFILE:
            - Fire: \(String(format: "%.1f", elements.fire))% (Direct, Motivational, Action-Oriented)
            - Earth: \(String(format: "%.1f", elements.earth))% (Practical, Grounded, Structured)
            - Air: \(String(format: "%.1f", elements.air))% (Curious, Expansive, Theoretical)
            - Water: \(String(format: "%.1f", elements.water))% (Intuitive, Poetic, Emotional)
            
            WRITING STYLE INSTRUCTIONS:
            Adjust your language based on the dominant element:
            - If Fire dominates (>35%): Use bold, imperative phrasing with short, direct sentences that inspire action
            - If Earth dominates (>35%): Use structured, practical language with clear steps and tangible advice
            - If Air dominates (>35%): Use exploratory language that presents possibilities and intellectual insights
            - If Water dominates (>35%): Use flowing, emotionally resonant language that speaks to feelings and inner experience
            - For balanced charts: Blend styles appropriately
            
            \(timeGuidance)
            
            INTERPRETATION GUIDELINES:
            1. Focus on evolutionary themes of growth, integration and purpose
            2. Be specific about how these planetary influences affect different life areas
            3. Present challenges as opportunities for growth
            4. Include practical guidance alongside spiritual insights
            5. Write in second person ("you") addressing the reader directly
            6. Provide 2-3 paragraphs of cohesive interpretation that synthesizes the most significant influences
            7. Avoid technical jargon when possible
            """
            
            // Create user message with transit data
            let userMessage = """
            Please create a personalized \(category) horoscope based on these current astrological influences:
            
            \(transits.joined(separator: "\n"))
            """
            
            // Use existing LilaAgentManager to send to AI service
            LilaAgentManager.shared.sendMessageToAgent(
                prompt: systemPrompt + "\n\n" + userMessage,
                userChart: chartCake,
                otherChart: nil
            ) { response in
                if let interpretation = response {
                    completion(.success(interpretation))
                } else {
                    let error = NSError(domain: "ForecastError",
                                       code: 1001,
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to generate forecast interpretation"])
                    completion(.failure(error))
                }
            }
        }
    }
