//
//  HoroscopeSpreadViewController.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/13/25.
//


import Foundation
import UIKit

class HoroscopeSpreadViewController: UIViewController {
    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let serviceSelector = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
    private let deckTypeSelector = UISegmentedControl(items: ["Church of Light", "Rider-Waite"])
    private var deckManager = ChurchOfLightDeckManager()
    private var riderWaiteDeckManager = RiderWaiteDeckManager()
    private var question: String = ""
    private var dealtCards: [ChurchOfLightTarotCard] = []
    private var dealtRiderWaiteCards: [RiderWaiteTarotCard] = []
    private var currentDeckType: TarotDeckType = .churchOfLight
    
    // Array of card views for all 12 cards
    private var cardViews = [UIImageView]()
    
    // Descriptions for the 12 houses in the horoscope
    let houseDescriptions = [
        "House 1: Self, Personal Traits, Health",
        "House 2: Honor, Business, Credit, Reputation",
        "House 3: Partners, Marriage, Open Enemies",
        "House 4: Home, Real Estate, End of Life",
        "House 5: Secret Afflictions, Restrictions",
        "House 6: Mind, Philosophy, Publishing, Travel",
        "House 7: Environment, Sickness, Labor",
        "House 8: Brethren, Studies, Writing, Journeys",
        "House 9: Friends, Associations, Hopes",
        "House 10: Death, Legacies, Partner's Money",
        "House 11: Children, Love Affairs, Pleasures",
        "House 12: Wealth, Cash, Personal Property"
    ]
    
    // Trines as described in the Sacred Tarot text
    let trineDescriptions = [
        "Trine of Life (Houses 1-6-11)",
        "Trine of Power (Houses 2-7-12)",
        "Social Trine (Houses 3-8-9)",
        "Trine of Concealed Things (Houses 4-10-5)"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Horoscope Spread"
        
        // Create card views for all 12 cards
        for _ in 0..<12 {
            let cardView = UIImageView()
            cardViews.append(cardView)
        }
        
        setupUI()
    }
    
    @objc private func serviceChanged() {
        switch serviceSelector.selectedSegmentIndex {
        case 0:
            TarotAIServiceManager.shared.currentProvider = .openAI
        case 1:
            TarotAIServiceManager.shared.currentProvider = .claude
        case 2:
            TarotAIServiceManager.shared.currentProvider = .huggingFace
        default:
            break
        }
    }
    
    @objc private func deckTypeChanged() {
        currentDeckType = deckTypeSelector.selectedSegmentIndex == 0 ? .churchOfLight : .riderWaite
        // Reset card displays when switching decks
        let backImageName = currentDeckType == .churchOfLight ? "col_cardBack" : "rw_cardBack"
        for cardView in cardViews {
            cardView.image = UIImage(named: backImageName)
            cardView.transform = .identity
        }
    }
    
    private func setupUI() {
        // 🔮 AI Service Selector
        serviceSelector.selectedSegmentIndex = 0
        serviceSelector.addTarget(self, action: #selector(serviceChanged), for: .valueChanged)
        serviceSelector.translatesAutoresizingMaskIntoConstraints = false
        
        // 🎴 Deck Type Selector
        deckTypeSelector.selectedSegmentIndex = 0
        deckTypeSelector.addTarget(self, action: #selector(deckTypeChanged), for: .valueChanged)
        deckTypeSelector.translatesAutoresizingMaskIntoConstraints = false
        
        // 🔍 Question Input
        questionField.placeholder = "Enter your question for the horoscope spread"
        questionField.borderStyle = .roundedRect
        questionField.translatesAutoresizingMaskIntoConstraints = false
        
        // 🎴 Ask Button
        askButton.setTitle("Ask the Cards", for: .normal)
        askButton.addTarget(self, action: #selector(handleAsk), for: .touchUpInside)
        askButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add spread description
        let descriptionLabel = UILabel()
        descriptionLabel.text = "The Horoscope Spread reveals the near future of every department of life through the 12 houses of astrology, arranged in four trines."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 📝 Result Scroll Area
        let scrollView = UIScrollView()
        let contentView = UIView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        resultLabel.textAlignment = .left
        resultLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        resultLabel.numberOfLines = 0
        
        // 📥 Add Subviews
        view.addSubview(serviceSelector)
        view.addSubview(deckTypeSelector)
        view.addSubview(descriptionLabel)
        view.addSubview(questionField)
        view.addSubview(askButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(resultLabel)
        
        // 🃏 Card Views setup
        for (i, cardView) in cardViews.enumerated() {
            let backImageName = currentDeckType == .churchOfLight ? "col_cardBack" : "rw_cardBack"
            cardView.image = UIImage(named: backImageName)
            cardView.contentMode = .scaleAspectFit
            cardView.layer.cornerRadius = 8
            cardView.clipsToBounds = true
            cardView.tag = i
            cardView.isUserInteractionEnabled = true
            cardView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cardView)
        }
        
        // Draw the grid pattern in the background
        drawHoroscopeGrid()
        
        // 📐 Setup basic constraints
        NSLayoutConstraint.activate([
            // Service Selector
            serviceSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            serviceSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Deck Type Selector
            deckTypeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            deckTypeSelector.leadingAnchor.constraint(equalTo: serviceSelector.trailingAnchor, constant: 10),
            deckTypeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Question Field
            questionField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Ask Button
            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 10),
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // ScrollView
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 150),
            
            // ScrollView Content
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Result Label
            resultLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            resultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Position the cards in the horoscope pattern
        layoutHoroscopeCards()
    }
    
    // Draw the background grid for the horoscope spread
    private func drawHoroscopeGrid() {
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()
        
        // Center point of the star
        let centerX = view.center.x
        let centerY = view.center.y + 50 // Adjusted for better visibility within the view
        
        // Dimensions for the star
        let outerRadius: CGFloat = min(view.frame.width * 0.4, 150)
        let innerRadius: CGFloat = outerRadius * 0.5
        
        // Draw the outer octagon (simplified for visualization)
        let numberOfPoints = 12
        var points: [CGPoint] = []
        
        for i in 0..<numberOfPoints {
            let angle = CGFloat(i) * (2.0 * .pi / CGFloat(numberOfPoints)) - (.pi / 12.0) // Offset slightly
            let x = centerX + outerRadius * cos(angle)
            let y = centerY + outerRadius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        // Draw the octagon
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.close()
        }
        
        // Draw central grid
        let gridSize: CGFloat = innerRadius * 1.2
        let cellSize = gridSize / 3
        
        // Vertical grid lines
        for i in 0...3 {
            let x = centerX - gridSize/2 + cellSize * CGFloat(i)
            path.move(to: CGPoint(x: x, y: centerY - gridSize/2))
            path.addLine(to: CGPoint(x: x, y: centerY + gridSize/2))
        }
        
        // Horizontal grid lines
        for i in 0...3 {
            let y = centerY - gridSize/2 + cellSize * CGFloat(i)
            path.move(to: CGPoint(x: centerX - gridSize/2, y: y))
            path.addLine(to: CGPoint(x: centerX + gridSize/2, y: y))
        }
        
        // Draw diagonals of the star
        path.move(to: points[0])
        path.addLine(to: points[6])
        path.move(to: points[1])
        path.addLine(to: points[7])
        path.move(to: points[2])
        path.addLine(to: points[8])
        path.move(to: points[3])
        path.addLine(to: points[9])
        path.move(to: points[4])
        path.addLine(to: points[10])
        path.move(to: points[5])
        path.addLine(to: points[11])
        
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
        shapeLayer.lineWidth = 1.0
        
        view.layer.addSublayer(shapeLayer)
    }
    
    // Layout the 12 cards in a star pattern
    private func layoutHoroscopeCards() {
        let cardWidth: CGFloat = 60
        let cardHeight: CGFloat = 90
        let radius: CGFloat = min(view.frame.width * 0.35, 130)
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY + 30 // Adjusted for space

        for (index, cardView) in cardViews.enumerated() {
            let angle = CGFloat(index) * (.pi * 2 / 12) - .pi / 2 // Start from top
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)

            cardView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cardView.widthAnchor.constraint(equalToConstant: cardWidth),
                cardView.heightAnchor.constraint(equalToConstant: cardHeight),
                cardView.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: x),
                cardView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: y)
            ])

            // Add number label
            let label = UILabel()
            label.text = "\(index + 1)"
            label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            label.textColor = .white
            label.textAlignment = .center
            label.backgroundColor = .systemIndigo.withAlphaComponent(0.7)
            label.layer.cornerRadius = 10
            label.layer.masksToBounds = true
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: cardView.topAnchor, constant: -4),
                label.widthAnchor.constraint(equalToConstant: 20),
                label.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
    }

    @objc private func handleAsk() {
        view.endEditing(true)
        question = questionField.text ?? ""
        guard !question.isEmpty else {
            resultLabel.text = "Please enter a question."
            return
        }
        
        // Reset cards to show backs with the correct deck-specific image
        let backImageName = currentDeckType == .churchOfLight ? "col_cardBack" : "rw_cardBack"
        for cardView in cardViews {
            cardView.image = UIImage(named: backImageName)
            cardView.transform = .identity
        }
        
        // Handle different deck types
        switch currentDeckType {
        case .churchOfLight:
            deckManager = ChurchOfLightDeckManager()
            deckManager.shuffleAndCut(times: 3)
            dealtCards = Array(deckManager.deck.prefix(12))
            interpretChurchOfLightHoroscope()
            
        case .riderWaite:
            riderWaiteDeckManager = RiderWaiteDeckManager()
            riderWaiteDeckManager.shuffleAndCut(times: 3)
            dealtRiderWaiteCards = Array(riderWaiteDeckManager.deck.prefix(12))
            interpretRiderWaiteHoroscope()
        }
        
        resultLabel.text = "Reading..."
    }
    
    private func interpretChurchOfLightHoroscope() {
        guard dealtCards.count == 12 else {
            print("❌ Error: You must have exactly 12 cards. Current count: \(dealtCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        // Log the cards
        for (i, card) in dealtCards.enumerated() {
            print("🃏 House \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Horoscope spread
        let promptBuilder = HoroscopePromptBuilder()
        let prompt = promptBuilder.buildHoroscopePrompt(
            question: question,
            cardNames: cardNames,
            deckType: .churchOfLight
        )
        
        // Use the selected AI service
        TarotAIServiceManager.shared.currentService.generateTarotReading(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let answer):
                    self?.resultLabel.text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Flip cards once answer is received
                    self?.flipChurchOfLightCards()
                case .failure(let error):
                    self?.resultLabel.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func interpretRiderWaiteHoroscope() {
        guard dealtRiderWaiteCards.count == 12 else {
            print("❌ Error: You must have exactly 12 cards. Current count: \(dealtRiderWaiteCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        // Log the cards
        for (i, card) in dealtRiderWaiteCards.enumerated() {
            print("🃏 House \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtRiderWaiteCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Horoscope spread
        let promptBuilder = HoroscopePromptBuilder()
        let prompt = promptBuilder.buildHoroscopePrompt(
            question: question,
            cardNames: cardNames,
            deckType: .riderWaite
        )
        
        // Use the selected AI service
        TarotAIServiceManager.shared.currentService.generateTarotReading(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let answer):
                    self?.resultLabel.text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Flip cards once answer is received
                    self?.flipRiderWaiteCards()
                case .failure(let error):
                    self?.resultLabel.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Flip animation for Church of Light cards
    private func flipChurchOfLightCards() {
        // Flip cards one at a time in order shown on the diagram (1-12)
        for i in 0..<12 {
            let card = dealtCards[i]
            let imageName = getChurchOfLightImageName(card)
            
            // Delay flipping each card by 0.25 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                guard let self = self else { return }
                
                // Perform flip animation
                UIView.transition(with: self.cardViews[i], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[i].image = UIImage(named: imageName)
                    
                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[i].transform = CGAffineTransform(rotationAngle: .pi)
                    }
                }, completion: nil)
            }
        }
    }
    
    // Flip animation for Rider-Waite cards
    private func flipRiderWaiteCards() {
        // Flip cards one at a time in order shown on the diagram (1-12)
        for i in 0..<12 {
            let card = dealtRiderWaiteCards[i]
            let imageName = getRiderWaiteImageName(card)
            
            // Delay flipping each card by 0.25 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                guard let self = self else { return }
                
                // Perform flip animation
                UIView.transition(with: self.cardViews[i], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[i].image = UIImage(named: imageName)
                    
                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[i].transform = CGAffineTransform(rotationAngle: .pi)
                    }
                }, completion: nil)
            }
        }
    }
    
    // Get image name for Church of Light card (same as in other view controllers)
    private func getChurchOfLightImageName(_ card: ChurchOfLightTarotCard) -> String {
        // Same implementation as in other view controllers
        let normalizedName = card.name.lowercased()
        
        // Major Arcana (0-21)
        if let arcanum = card.arcanum {
            // Extract number from arcanum
            let numberString: String
            if arcanum.contains("XXII") || arcanum.contains("0") {
                numberString = "00" // The Fool
            } else if let arcNum = Int(arcanum.filter({ $0.isNumber })) {
                numberString = String(format: "%02d", arcNum)
            } else {
                // Handle roman numerals (simplified)
                let romanNumerals = ["I": "01", "II": "02", "III": "03", "IV": "04", "V": "05",
                                    "VI": "06", "VII": "07", "VIII": "08", "IX": "09", "X": "10",
                                    "XI": "11", "XII": "12", "XIII": "13", "XIV": "14", "XV": "15",
                                    "XVI": "16", "XVII": "17", "XVIII": "18", "XIX": "19", "XX": "20", "XXI": "21"]
                numberString = romanNumerals[arcanum] ?? "00"
            }
            
            return "col_major\(numberString)"
        }
        
        // Minor Arcana
        if normalizedName.contains("of") {
            // Get suit initial
            let suitInitial: String
            if normalizedName.contains("scepters") || normalizedName.contains("wands") {
                suitInitial = "w" // wands
            } else if normalizedName.contains("cups") {
                suitInitial = "c" // cups
            } else if normalizedName.contains("swords") {
                suitInitial = "s" // swords
            } else if normalizedName.contains("coins") || normalizedName.contains("pentacles") {
                suitInitial = "p" // pentacles/coins
            } else {
                suitInitial = "x" // unknown
            }
            
            // Handle court cards
            if normalizedName.contains("king") {
                return "col_\(suitInitial)k"
            } else if normalizedName.contains("queen") {
                return "col_\(suitInitial)q"
            } else if normalizedName.contains("youth") || normalizedName.contains("page") {
                return "col_\(suitInitial)y"
            } else if normalizedName.contains("horseman") || normalizedName.contains("knight") {
                return "col_\(suitInitial)h"
            }
            
            // Handle numbered cards
            let numbersText = ["ace": "01", "two": "02", "three": "03", "four": "04", "five": "05",
                              "six": "06", "seven": "07", "eight": "08", "nine": "09", "ten": "10"]
            
            for (word, num) in numbersText {
                if normalizedName.contains(word) {
                    return "col_\(suitInitial)\(num)"
                }
            }
        }
        
        return "col_cardFront"
    }
    
    // Get image name for Rider-Waite card (same as in other view controllers)
    private func getRiderWaiteImageName(_ card: RiderWaiteTarotCard) -> String {
        // Same implementation as in other view controllers
        let normalizedName = card.name.lowercased()
        
        // Major Arcana (0-21)
        if let arcanum = card.arcanum {
            // Extract number from arcanum
            let numberString: String
            if arcanum == "0" {
                numberString = "00" // The Fool
            } else {
                numberString = String(format: "%02d", Int(arcanum) ?? 0)
            }
            
            return "rw_major\(numberString)"
        }
        
        // Minor Arcana
        if normalizedName.contains("of") {
            // Get suit initial
            let suitInitial: String
            if normalizedName.contains("wands") {
                suitInitial = "w" // wands
            } else if normalizedName.contains("cups") {
                suitInitial = "c" // cups
            } else if normalizedName.contains("swords") {
                suitInitial = "s" // swords
            } else if normalizedName.contains("pentacles") {
                suitInitial = "p" // pentacles
            } else {
                suitInitial = "x" // unknown
            }
            
            // Handle court cards
            if normalizedName.contains("king") {
                return "rw_\(suitInitial)k"
            } else if normalizedName.contains("queen") {
                return "rw_\(suitInitial)q"
            } else if normalizedName.contains("page") {
                return "rw_\(suitInitial)p"
            } else if normalizedName.contains("knight") {
                return "rw_\(suitInitial)n"
            }
            
            // Handle numbered cards
            let numbersText = ["ace": "01", "two": "02", "three": "03", "four": "04", "five": "05",
                              "six": "06", "seven": "07", "eight": "08", "nine": "09", "ten": "10"]
            
            for (word, num) in numbersText {
                if normalizedName.contains(word) {
                    return "rw_\(suitInitial)\(num)"
                }
            }
        }
        
        return "rw_cardFront"
    }
}

// Create a separate prompt builder for Horoscope spread
class HoroscopePromptBuilder {
    func buildHoroscopePrompt(question: String, cardNames: [String], deckType: TarotDeckType) -> String {
        let houseDescriptions = [
            "House 1: Self, Personal Traits, Health",
            "House 2: Honor, Business, Credit, Reputation",
            "House 3: Partners, Marriage, Open Enemies",
            "House 4: Home, Real Estate, End of Life",
            "House 5: Secret Afflictions, Restrictions",
            "House 6: Mind, Philosophy, Publishing, Travel",
            "House 7: Environment, Sickness, Labor",
            "House 8: Brethren, Studies, Writing, Journeys",
            "House 9: Friends, Associations, Hopes",
            "House 10: Death, Legacies, Partner's Money",
            "House 11: Children, Love Affairs, Pleasures",
            "House 12: Wealth, Cash, Personal Property"
        ]

        let trineDescriptions = [
            "Trine of Life (Houses 1-6-11): Personal health, mind, and posterity",
            "Trine of Power (Houses 2-7-12): Honor, environment, and wealth",
            "Social Trine (Houses 3-8-9): Partners, kindred, and associates",
            "Trine of Concealed Things (Houses 4-10-5): Home, death, and afflictions"
        ]

        var prompt = """
        # HERMETIC HOROSCOPE TAROT READING
        
        ## Question
        "\(question)"
        
        ## Spread
        Horoscope Spread (12 houses of the astrological chart)
        
        ## Houses and Cards
        
        """

        // Add each card with its house description
        for (index, cardName) in cardNames.enumerated() {
            if index < houseDescriptions.count {
                prompt += """
                
                ### \(houseDescriptions[index])
                Card: \(cardName)
                
                """
            }
        }

        // Add trine information
        prompt += """
        
        ## Trines
        
        """

        for trine in trineDescriptions {
            prompt += "\(trine)\n"
        }

        // Add interpretation guidelines
        prompt += """
        
        ## Interpretation Guidelines
        
        Please provide a Sacred Tarot interpretation of this Horoscope spread that:
        
        1. **Analyzes each house** and what the card in that position reveals about that area of life.
        
        2. **Examines each trine** as a group to find patterns and connections:
           - The Trine of Life (Houses 1-6-11) reveals the querent's vitality, mental approach, and joy
           - The Trine of Power (Houses 2-7-12) shows sources of strength, challenges, and material security
           - The Social Trine (Houses 3-8-9) illuminates relationships with others
           - The Trine of Concealed Things (Houses 4-10-5) uncovers hidden factors
        
        3. **Identifies Major Arcana cards** in the spread, as these represent significant cosmic forces at work.
        
        4. **Creates a cohesive narrative** that gives the querent insight into every department of their life.
        
        5. **Notes whether cards are good or evil** in their positions, as a good card falling on any house signifies good luck in that department of life, while an evil card signifies challenges.
        
        Keep your interpretation dignified and illuminating, focusing on how the cosmic forces revealed by this spread can guide the querent's decisions. Remember that "the stars impel, they do not compel."
        """

        return prompt
    }
}
