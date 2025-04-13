//
//  MagicSevenSpreadViewController.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/13/25.
//


import Foundation
import UIKit

class MagicSevenSpreadViewController: UIViewController {
    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let cardViews = [UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    private let resultLabel = UILabel()
    private let serviceSelector = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
    private let deckTypeSelector = UISegmentedControl(items: ["Church of Light", "Rider-Waite"])
    private var deckManager = ChurchOfLightDeckManager()
    private var riderWaiteDeckManager = RiderWaiteDeckManager()
    private var question: String = ""
    private var dealtCards: [ChurchOfLightTarotCard] = []
    private var dealtRiderWaiteCards: [RiderWaiteTarotCard] = []
    private var currentDeckType: TarotDeckType = .churchOfLight
    
    // Position meanings according to Sacred Tarot text
    let positionMeanings = [
        "1. Past (Upper Jod) - The Cause",
        "2. Present (Upper He) - The Effect",
        "3. Immediate Future (Upper Vau)",
        "4. Power to Control (Lower Jod)",
        "5. Fate & Environment (Lower He)",
        "6. Opposition (Lower Vau)",
        "7. Final Outcome (Final He)"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Magic Seven Spread"
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
        
        // 📝 Result Scroll Area
        let scrollView = UIScrollView()
        let contentView = UIView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        resultLabel.textAlignment = .left
        resultLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        resultLabel.numberOfLines = 0
        
        // Add spread description
        let descriptionLabel = UILabel()
        descriptionLabel.text = "The Magic Seven Spread uses the Seal of Solomon to address questions about external life. Seven completes a form, and this spread reveals how forces combine to create the final outcome."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        // 📥 Add Subviews
        view.addSubview(serviceSelector)
        view.addSubview(deckTypeSelector)
        view.addSubview(questionField)
        view.addSubview(askButton)
        view.addSubview(descriptionLabel)
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
        
        // Draw the Seal of Solomon
        setupSealOfSolomon()
        
        // 📐 Constraints
        NSLayoutConstraint.activate([
            // Service Selector
            serviceSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            serviceSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Deck Type Selector
            deckTypeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            deckTypeSelector.leadingAnchor.constraint(equalTo: serviceSelector.trailingAnchor, constant: 10),
            deckTypeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Question Field
            questionField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Ask Button
            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 12),
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

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
        
        // Position the 7 cards in the Seal of Solomon pattern
        layoutMagicSevenCards()
    }
    
    private func setupSealOfSolomon() {
        let centerX = view.center.x
        let centerY = view.center.y - 30 // Adjusted for better visibility
        let radius: CGFloat = min(view.frame.width * 0.30, 130) // Scale with screen size
        
        // Create a shape layer for the hexagram
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()
        
        // Calculate points for the hexagram
        let points: [CGPoint] = [
            CGPoint(x: centerX, y: centerY - radius), // Top
            CGPoint(x: centerX + radius * 0.866, y: centerY - radius * 0.5), // Upper right
            CGPoint(x: centerX + radius * 0.866, y: centerY + radius * 0.5), // Lower right
            CGPoint(x: centerX, y: centerY + radius), // Bottom
            CGPoint(x: centerX - radius * 0.866, y: centerY + radius * 0.5), // Lower left
            CGPoint(x: centerX - radius * 0.866, y: centerY - radius * 0.5) // Upper left
        ]
        
        // Draw first triangle
        path.move(to: points[0])
        path.addLine(to: points[2])
        path.addLine(to: points[4])
        path.close()
        
        // Draw second triangle
        path.move(to: points[1])
        path.addLine(to: points[3])
        path.addLine(to: points[5])
        path.close()
        
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
        shapeLayer.lineWidth = 1.0
        
        view.layer.addSublayer(shapeLayer)
    }
    
    private func layoutMagicSevenCards() {
        let cardWidth: CGFloat = 60
        let cardHeight: CGFloat = 90
        let centerX = view.center.x
        let centerY = view.center.y - 30 // Adjusted for better visibility
        let radius: CGFloat = min(view.frame.width * 0.30, 130) // Scale with screen size
        
        // Calculate positions based on the Seal of Solomon diagram
        var cardPositions: [CGPoint] = []
        
        // Card 1 - Top
        cardPositions.append(CGPoint(x: centerX, y: centerY - radius))
        
        // Card 2 - Upper Right
        cardPositions.append(CGPoint(x: centerX + radius * 0.866, y: centerY - radius * 0.5))
        
        // Card 3 - Lower Right
        cardPositions.append(CGPoint(x: centerX + radius * 0.866, y: centerY + radius * 0.5))
        
        // Card 4 - Bottom
        cardPositions.append(CGPoint(x: centerX, y: centerY + radius))
        
        // Card 5 - Lower Left
        cardPositions.append(CGPoint(x: centerX - radius * 0.866, y: centerY + radius * 0.5))
        
        // Card 6 - Upper Left
        cardPositions.append(CGPoint(x: centerX - radius * 0.866, y: centerY - radius * 0.5))
        
        // Card 7 - Center
        cardPositions.append(CGPoint(x: centerX, y: centerY))
        
        // Position each card
        for (index, position) in cardPositions.enumerated() {
            NSLayoutConstraint.activate([
                cardViews[index].centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: position.x),
                cardViews[index].centerYAnchor.constraint(equalTo: view.topAnchor, constant: position.y),
                cardViews[index].widthAnchor.constraint(equalToConstant: cardWidth),
                cardViews[index].heightAnchor.constraint(equalToConstant: cardHeight)
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
            deckManager.shuffleAndCut()
            dealtCards = Array(deckManager.deck.prefix(7))
            interpretChurchOfLightMagicSeven()
            
        case .riderWaite:
            riderWaiteDeckManager = RiderWaiteDeckManager()
            riderWaiteDeckManager.shuffleAndCut()
            dealtRiderWaiteCards = Array(riderWaiteDeckManager.deck.prefix(7))
            interpretRiderWaiteMagicSeven()
        }
        
        resultLabel.text = "Reading..."
    }
    
    private func interpretChurchOfLightMagicSeven() {
        guard dealtCards.count == 7 else {
            print("❌ Error: You must have exactly 7 cards. Current count: \(dealtCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        for (i, card) in dealtCards.enumerated() {
            print("🃏 Card \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Magic Seven spread
        let promptBuilder = MagicSevenPromptBuilder()
        let prompt = promptBuilder.buildMagicSevenPrompt(
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
    
    private func interpretRiderWaiteMagicSeven() {
        guard dealtRiderWaiteCards.count == 7 else {
            print("❌ Error: You must have exactly 7 cards. Current count: \(dealtRiderWaiteCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }
        
        for (i, card) in dealtRiderWaiteCards.enumerated() {
            print("🃏 Card \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }
        
        let cardNames = dealtRiderWaiteCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }
        
        // Create a specialized prompt builder for Magic Seven spread
        let promptBuilder = MagicSevenPromptBuilder()
        let prompt = promptBuilder.buildMagicSevenPrompt(
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
        // Follow the numbered order from the diagram (1-7)
        let cardPositions = [
            0, // Card 1 - Top
            2, // Card 2 - Lower Right
            4, // Card 3 - Lower Left
            3, // Card 4 - Bottom
            5, // Card 5 - Upper Left
            1, // Card 6 - Upper Right
            6  // Card 7 - Center
        ]

        for (i, index) in cardPositions.enumerated() {
            let card = dealtCards[index]
            let imageName = getChurchOfLightImageName(card)

            // Delay flipping each card
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) { [weak self] in
                guard let self = self else { return }

                // Perform flip animation
                UIView.transition(with: self.cardViews[index], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[index].image = UIImage(named: imageName)

                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[index].transform = CGAffineTransform(rotationAngle: .pi)
                    }
                }, completion: nil)
            }
        }
    }

    // Flip animation for Rider-Waite cards
    private func flipRiderWaiteCards() {
        // Follow the numbered order from the diagram (1-7)
        let cardPositions = [
            0, // Card 1 - Top
            2, // Card 2 - Lower Right
            4, // Card 3 - Lower Left
            3, // Card 4 - Bottom
            5, // Card 5 - Upper Left
            1, // Card 6 - Upper Right
            6  // Card 7 - Center
        ]

        for (i, index) in cardPositions.enumerated() {
            let card = dealtRiderWaiteCards[index]
            let imageName = getRiderWaiteImageName(card)

            // Delay flipping each card
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) { [weak self] in
                guard let self = self else { return }

                // Perform flip animation
                UIView.transition(with: self.cardViews[index], duration: 0.5, options: .transitionFlipFromTop, animations: {
                    // Change the image to the card front during the animation
                    self.cardViews[index].image = UIImage(named: imageName)

                    // Apply rotation if card is reversed
                    if card.isReversed {
                        self.cardViews[index].transform = CGAffineTransform(rotationAngle: .pi)
                    }
                }, completion: nil)
            }
        }
    }
    // Get image name for Church of Light card (same as in YesNoTarotViewController)
    private func getChurchOfLightImageName(_ card: ChurchOfLightTarotCard) -> String {
        // Same implementation as in YesNoTarotViewController
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
    
    // Get image name for Rider-Waite card (same as in YesNoTarotViewController)
    private func getRiderWaiteImageName(_ card: RiderWaiteTarotCard) -> String {
        // Same implementation as in YesNoTarotViewController
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

// Create a separate prompt builder for Magic Seven
class MagicSevenPromptBuilder {
    func buildMagicSevenPrompt(question: String, cardNames: [String], deckType: TarotDeckType) -> String {
        // Position meanings according to Sacred Tarot
        let positions = [
            "Past (Upper Jod) - The Cause",
            "Present (Upper He) - The Effect",
            "Immediate Future (Upper Vau)",
            "Power to Control (Lower Jod)",
            "Fate & Environment (Lower He)",
            "Opposition (Lower Vau)",
            "Final Outcome (Final He)"
        ]
        
        var prompt = """
        # HERMETIC MAGIC SEVEN TAROT READING
        
        ## Question
        "\(question)"
        
        ## Spread
        Magic Seven Spread (Solomon's Seal)
        
        ## Cards in Position
        
        """
        
        // Add each card with its position
        for (index, cardName) in cardNames.enumerated() {
            if index < positions.count {
                let position = positions[index]
                
                prompt += """
                
                ### Position \(index + 1): \(position)
                Card: \(cardName)
                
                """
            }
        }
        
        // Add interpretation guidelines
        prompt += """
        
        ## Interpretation Guidelines
        
        Please provide a Sacred Tarot interpretation of this Magic Seven spread that:
        
        1. **Tells the story revealed by the cards** as a cohesive narrative flowing from past to future through the Seal of Solomon:
           - Begin with a compelling introduction about how the question relates to the cosmic forces
           - Explain how past causes (Card 1) have led to present effects (Card 2)
           - Show how the immediate future (Card 3) emerges from these
           - Analyze the querent's power to control the situation (Card 4)
           - Describe the role of fate and environment (Card 5)
           - Identify opposing forces (Card 6)
           - Conclude with the final outcome (Card 7) after all factors have undergone gestation
           
        2. **Card-by-Card Analysis**:
           - Focus on each card's astrological correspondences
           - Explain how each card's position in the Seal of Solomon amplifies or modifies its meaning
           - Connect each card to the specific context of the question
           
        3. **Pattern Analysis**:
           - Identify dominant elements or astrological influences
           - Note any significant patterns across the seven positions
           
        4. **Hermetic Synthesis**:
           - Explain how the cards demonstrate the operation of hermetic principles
           - Show how "as above, so below" manifests in the querent's situation
           
        Keep your interpretation dignified and illuminating, focusing on spiritual evolution rather than mere prediction. Remember that "the stars impel, they do not compel."
        """
        
        return prompt
    }
}
