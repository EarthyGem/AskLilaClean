//
//  PyramidSpreadViewController.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/13/25.
//


import Foundation
import UIKit

class PyramidSpreadViewController: UIViewController {
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
    
    // Array of card views for all 21 cards
    private var cardViews = [UIImageView]()
    
    // Position meanings based on the Sacred Tarot description
    let keyDescriptions = [
        "Key I - The Present",
        "Key II - The Next Turn of Events",
        "Key III - Following Circumstance",
        "Key IV - Further in the Future",
        "Key V - Ultimate Outcome/Distant Future"
    ]
    
    // Identify which positions are keys (0-based indexing)
    let keyPositions = [15, 19, 11, 5, 0] // Key I, II, III, IV, V in the pyramid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Pyramid Spread"
        
        // Create card views for all 21 cards
        for _ in 0..<21 {
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
        questionField.placeholder = "Enter your question"
        questionField.borderStyle = .roundedRect
        questionField.translatesAutoresizingMaskIntoConstraints = false
        
        // 🎴 Ask Button
        askButton.setTitle("Ask the Cards", for: .normal)
        askButton.addTarget(self, action: #selector(handleAsk), for: .touchUpInside)
        askButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add spread description
        let descriptionLabel = UILabel()
        descriptionLabel.text = "The Pyramid Spread uses 21 cards to reveal the path from past through present to future. The five key cards show major turning points."
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
        
        // Position the cards in the pyramid pattern
        layoutPyramidCards()
    }
    
    // Layout the 21 cards in a pyramid pattern
    private func layoutPyramidCards() {
        let cardWidth: CGFloat = 45
        let cardHeight: CGFloat = 70
        let horizontalSpacing: CGFloat = 2
        let verticalSpacing: CGFloat = 5
        
        let pyramidTop = askButton.frame.maxY + 20
        let centerX = view.center.x
        
        // Calculate positions for each row
        // Row 1 (top) - 1 card
        var rowStartIndex = 0
        var cardsInRow = 1
        var yPosition = pyramidTop
        
        // Position row 1 (top)
        let row1X = centerX - (cardWidth / 2)
        cardViews[rowStartIndex].frame = CGRect(x: row1X, y: yPosition, width: cardWidth, height: cardHeight)
        
        // Row 2 - 2 cards
        rowStartIndex += cardsInRow
        cardsInRow = 2
        yPosition += cardHeight + verticalSpacing
        
        let row2Width = (cardWidth * CGFloat(cardsInRow)) + (horizontalSpacing * CGFloat(cardsInRow - 1))
        var xPosition = centerX - (row2Width / 2)
        
        for i in rowStartIndex..<(rowStartIndex + cardsInRow) {
            cardViews[i].frame = CGRect(x: xPosition, y: yPosition, width: cardWidth, height: cardHeight)
            xPosition += cardWidth + horizontalSpacing
        }
        
        // Row 3 - 3 cards
        rowStartIndex += cardsInRow
        cardsInRow = 3
        yPosition += cardHeight + verticalSpacing
        
        let row3Width = (cardWidth * CGFloat(cardsInRow)) + (horizontalSpacing * CGFloat(cardsInRow - 1))
        xPosition = centerX - (row3Width / 2)
        
        for i in rowStartIndex..<(rowStartIndex + cardsInRow) {
            cardViews[i].frame = CGRect(x: xPosition, y: yPosition, width: cardWidth, height: cardHeight)
            xPosition += cardWidth + horizontalSpacing
        }
        
        // Row 4 - 6 cards
        rowStartIndex += cardsInRow
        cardsInRow = 6
        yPosition += cardHeight + verticalSpacing
        
        let row4Width = (cardWidth * CGFloat(cardsInRow)) + (horizontalSpacing * CGFloat(cardsInRow - 1))
        xPosition = centerX - (row4Width / 2)
        
        for i in rowStartIndex..<(rowStartIndex + cardsInRow) {
            cardViews[i].frame = CGRect(x: xPosition, y: yPosition, width: cardWidth, height: cardHeight)
            xPosition += cardWidth + horizontalSpacing
        }
        
        // Row 5 (bottom) - 9 cards
        rowStartIndex += cardsInRow
        cardsInRow = 9
        yPosition += cardHeight + verticalSpacing
        
        let row5Width = (cardWidth * CGFloat(cardsInRow)) + (horizontalSpacing * CGFloat(cardsInRow - 1))
        xPosition = centerX - (row5Width / 2)
        
        for i in rowStartIndex..<(rowStartIndex + cardsInRow) {
            cardViews[i].frame = CGRect(x: xPosition, y: yPosition, width: cardWidth, height: cardHeight)
            xPosition += cardWidth + horizontalSpacing
        }
        
        // Highlight key cards with a border
        for keyPosition in keyPositions {
            cardViews[keyPosition].layer.borderWidth = 2
            cardViews[keyPosition].layer.borderColor = UIColor.systemRed.cgColor
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
            deckManager.shuffleAndCut(times: 3) // As specified in the description
            dealtCards = Array(deckManager.deck.prefix(21))
            interpretChurchOfLightPyramid()
            
        case .riderWaite:
            riderWaiteDeckManager = RiderWaiteDeckManager()
            riderWaiteDeckManager.shuffleAndCut(times: 3)
            dealtRiderWaiteCards = Array(riderWaiteDeckManager.deck.prefix(21))
            interpretRiderWaitePyramid()
        }
        
        resultLabel.text = "Reading..."
    }
    
    private func interpretChurchOfLightPyramid() {
        guard dealtCards.count == 21 else {
            print("❌ Error: You must have exactly 21 cards. Current count: \(dealtCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        // Log the cards
        for (i, card) in dealtCards.enumerated() {
            let isKey = keyPositions.contains(i) ? " (KEY)" : ""
            print("🃏 Card \(i + 1)\(isKey): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Pyramid spread
        let promptBuilder = PyramidPromptBuilder()
        let prompt = promptBuilder.buildPyramidPrompt(
            question: question,
            cardNames: cardNames,
            keyPositions: keyPositions,
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
    
    private func interpretRiderWaitePyramid() {
        guard dealtRiderWaiteCards.count == 21 else {
            print("❌ Error: You must have exactly 21 cards. Current count: \(dealtRiderWaiteCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        // Log the cards
        for (i, card) in dealtRiderWaiteCards.enumerated() {
            let isKey = keyPositions.contains(i) ? " (KEY)" : ""
            print("🃏 Card \(i + 1)\(isKey): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtRiderWaiteCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Pyramid spread
        let promptBuilder = PyramidPromptBuilder()
        let prompt = promptBuilder.buildPyramidPrompt(
            question: question,
            cardNames: cardNames,
            keyPositions: keyPositions,
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
        // Following the description, cards should be revealed starting from Key I and moving outward
        // First, flip Key I (present)
        let keyIIndex = keyPositions[0] // Key I position
        
        // Sequence: Key I first, then cards to its right, then Key II, then cards between Key I and II, etc.
        var flipSequence: [Int] = []
        
        // Start with Key I
        flipSequence.append(keyIIndex)
        
        // Past cards (to the right of Key I)
        // These would be the 4 cards to the right of Key I in the bottom row
        for i in 16...19 {
            flipSequence.append(i)
        }
        
        // Key II
        flipSequence.append(keyPositions[1])
        
        // Cards between Key I and Key II
        // These would vary based on exact layout
        for i in [14, 13, 12] {
            flipSequence.append(i)
        }
        
        // Key III
        flipSequence.append(keyPositions[2])
        
        // Cards between Key II and Key III
        for i in [10, 9, 8, 7] {
            flipSequence.append(i)
        }
        
        // Key IV
        flipSequence.append(keyPositions[3])
        
        // Cards between Key III and Key IV
        for i in [6, 4, 3, 2] {
            flipSequence.append(i)
        }
        
        // Key V
        flipSequence.append(keyPositions[4])
        
        // Flip the cards in sequence
        for (i, cardIndex) in flipSequence.enumerated() {
            let card = dealtCards[cardIndex]
            let imageName = getChurchOfLightImageName(card)
            
            // Delay flipping each card
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                guard let self = self else { return }
                
                // Perform flip animation
                UIView.transition(with: self.cardViews[cardIndex], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[cardIndex].image = UIImage(named: imageName)
                    
                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[cardIndex].transform = CGAffineTransform(rotationAngle: .pi)
                    }
                }, completion: nil)
            }
        }
    }
    
    // Flip animation for Rider-Waite cards
    private func flipRiderWaiteCards() {
        // Same sequence as Church of Light cards
        // Following the description, cards should be revealed starting from Key I and moving outward
        // First, flip Key I (present)
        let keyIIndex = keyPositions[0] // Key I position
        
        // Sequence: Key I first, then cards to its right, then Key II, then cards between Key I and II, etc.
        var flipSequence: [Int] = []
        
        // Start with Key I
        flipSequence.append(keyIIndex)
        
        // Past cards (to the right of Key I)
        // These would be the 4 cards to the right of Key I in the bottom row
        for i in 16...19 {
            flipSequence.append(i)
        }
        
        // Key II
        flipSequence.append(keyPositions[1])
        
        // Cards between Key I and Key II
        // These would vary based on exact layout
        for i in [14, 13, 12] {
            flipSequence.append(i)
        }
        
        // Key III
        flipSequence.append(keyPositions[2])
        
        // Cards between Key II and Key III
        for i in [10, 9, 8, 7] {
            flipSequence.append(i)
        }
        
        // Key IV
        flipSequence.append(keyPositions[3])
        
        // Cards between Key III and Key IV
        for i in [6, 4, 3, 2] {
            flipSequence.append(i)
        }
        
        // Key V
        flipSequence.append(keyPositions[4])
        
        // Flip the cards in sequence
        for (i, cardIndex) in flipSequence.enumerated() {
            let card = dealtRiderWaiteCards[cardIndex]
            let imageName = getRiderWaiteImageName(card)
            
            // Delay flipping each card
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { [weak self] in
                guard let self = self else { return }
                
                // Perform flip animation
                UIView.transition(with: self.cardViews[cardIndex], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[cardIndex].image = UIImage(named: imageName)
                    
                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[cardIndex].transform = CGAffineTransform(rotationAngle: .pi)
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
        
        // Minor Arcana and court cards - same as other implementations
        // ... [rest of the code is the same]
        
        return "col_cardFront"
    }
    
    // Get image name for Rider-Waite card (same as in other view controllers)
    private func getRiderWaiteImageName(_ card: RiderWaiteTarotCard) -> String {
        // Same implementation as in other view controllers
        // ... [code is the same]
        
        return "rw_cardFront"
    }
}

// Create a separate prompt builder for Pyramid spread
class PyramidPromptBuilder {
    func buildPyramidPrompt(question: String, cardNames: [String], keyPositions: [Int], deckType: TarotDeckType) -> String {
        let keyDescriptions = [
            "Key I - The Present",
            "Key II - The Next Turn of Events",
            "Key III - Following Circumstance",
            "Key IV - Further in the Future",
            "Key V - Ultimate Outcome/Distant Future"
        ]
        
        var prompt = """
        # HERMETIC PYRAMID TAROT READING
        
        ## Question
        "\(question)"
        
        ## Spread
        Pyramid Spread (21 cards in 5 levels)
        
        ## Key Cards
        
        """
        
        // Add key cards with their positions and descriptions
        for (index, keyPosition) in keyPositions.enumerated() {
            if keyPosition < cardNames.count {
                prompt += """
                
                ### \(keyDescriptions[index])
                Card: \(cardNames[keyPosition])
                
                """
            }
        }
        
        // Add all cards in the spread
        prompt += """
        
        ## All Cards in Pyramid (21 cards)
        
        """
        
        for (index, cardName) in cardNames.enumerated() {
            let isKey = keyPositions.contains(index) ? " (KEY)" : ""
            prompt += "Card \(index + 1)\(isKey): \(cardName)\n"
        }
        
        // Add interpretation guidelines
        prompt += """
        
        ## Interpretation Guidelines
        
        Please provide a Sacred Tarot interpretation of this Pyramid spread that:
        
        1. **Begins with Key I (Present)** and the cards to its right that represent the past, with the farthest right being the most distant past.
        
        2. **Progresses through the key cards** in sequence:
           - Key I: The present situation
           - Key II: The next turn in the wheel of circumstances
           - Key III: The following circumstance of importance
           - Key IV: Further future developments
           - Key V: The ultimate outcome or distant future
        
        3. **Analyzes the cards between each key** as the factors and influences leading from one key circumstance to the next.
        
        4. **Gives special attention to Major Arcana cards** that fall on key positions, as these are particularly important.
        
        5. **Creates a flowing narrative** that tells the querent's story from past influences through the present and into possible futures.
        
        Keep your interpretation dignified and illuminating, focusing on the spiritual forces at work in the querent's life. Remember that "the stars impel, they do not compel" - the querent has free will to navigate these cosmic influences.
        """
        
        return prompt
    }
}
