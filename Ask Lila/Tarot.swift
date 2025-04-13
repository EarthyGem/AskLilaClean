import Foundation
import UIKit

struct ChurchOfLightTarotCard: Identifiable {
    let id = UUID()
    let name: String
    let arcanum: String?
    let astrological: String?
    let hebrew: String?
    let color: String?
    let element: String?
    let metal: String?
    let divinatory: String?
    let innerMeaning: String?
    let suit: String?
    let isReversed: Bool

    static func from(dictionary: [String: String], name: String, isReversed: Bool = false) -> ChurchOfLightTarotCard {
        return ChurchOfLightTarotCard(
            name: name,
            arcanum: dictionary["Arcanum"],
            astrological: dictionary["Astrological"],
            hebrew: dictionary["Hebrew"],
            color: dictionary["Color"],
            element: dictionary["Element"],
            metal: dictionary["Metal"],
            divinatory: dictionary["Divinatory"],
            innerMeaning: dictionary["Inner Meaning"],
            suit: dictionary["Suit"],
            isReversed: isReversed
        )
    }
}



// Add a TarotDeckType enum to switch between decks
enum TarotDeckType {
    case churchOfLight
    case riderWaite
}

class YesNoTarotViewController: UIViewController {
    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let cardViews = [UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView()]
    private let resultLabel = UILabel()
    private let serviceSelector = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
    private let deckTypeSelector = UISegmentedControl(items: ["Church of Light", "Rider-Waite"])
    private var deckManager = ChurchOfLightDeckManager()
    private var riderWaiteDeckManager = RiderWaiteDeckManager() // Add a second deck manager
    private var question: String = ""
    private var dealtCards: [ChurchOfLightTarotCard] = []
    private var dealtRiderWaiteCards: [RiderWaiteTarotCard] = [] // For Rider-Waite cards
    private var currentDeckType: TarotDeckType = .churchOfLight

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
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

    // In deckTypeChanged() method:
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
        questionField.placeholder = "Enter your yes/no question"
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

        // 📥 Add Subviews
        view.addSubview(serviceSelector)
        view.addSubview(deckTypeSelector)
        view.addSubview(questionField)
        view.addSubview(askButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(resultLabel)

        // 🃏 Card Views - Now using UIImageView instead of UIView
        // 🃏 Card Views - Now using UIImageView instead of UIView
        for (i, cardView) in cardViews.enumerated() {
            // Use the appropriate card back based on current deck type
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

        // 📐 Constraints
        NSLayoutConstraint.activate([
            // Service Selector
            serviceSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            serviceSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Deck Type Selector
            deckTypeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            deckTypeSelector.leadingAnchor.constraint(equalTo: serviceSelector.trailingAnchor, constant: 10),
            deckTypeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Question Field
            questionField.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 12),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Ask Button
            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 12),
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: askButton.bottomAnchor, constant: 180),
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

        // 🃏 Card Layout
        for (index, cardView) in cardViews.enumerated() {
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: askButton.bottomAnchor, constant: 30),
                cardView.widthAnchor.constraint(equalToConstant: 70),
                cardView.heightAnchor.constraint(equalToConstant: 110)
            ])

            if index == 0 {
                cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
            } else {
                cardView.leadingAnchor.constraint(equalTo: cardViews[index - 1].trailingAnchor, constant: 10).isActive = true
            }
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
            dealtCards = Array(deckManager.deck.prefix(5))
            interpretChurchOfLightYesNo()

        case .riderWaite:
            riderWaiteDeckManager = RiderWaiteDeckManager()
            riderWaiteDeckManager.shuffleAndCut()
            dealtRiderWaiteCards = Array(riderWaiteDeckManager.deck.prefix(5))
            interpretRiderWaiteYesNo()
        }

        resultLabel.text = "Reading..."
    }
    private func interpretChurchOfLightYesNo() {
        guard dealtCards.count == 5 else {
            print("❌ Error: You must have exactly 5 cards. Current count: \(dealtCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }

        for (i, card) in dealtCards.enumerated() {
            print("🃏 Card \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }

        let cardNames = dealtCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }

        let promptBuilder = ChurchOfLightTarotPromptBuilder()
        let prompt = promptBuilder.buildYesNoSpread(
            question: question,
            cardNames: cardNames
        )

        // ✅ Use the currently selected Tarot service
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

    private func interpretRiderWaiteYesNo() {
        guard dealtRiderWaiteCards.count == 5 else {
            print("❌ Error: You must have exactly 5 cards. Current count: \(dealtRiderWaiteCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }

        for (i, card) in dealtRiderWaiteCards.enumerated() {
            print("🃏 Card \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }

        let cardNames = dealtRiderWaiteCards.map { "\($0.name)\($0.isReversed ? " (Reversed)" : "")" }

        let promptBuilder = RiderWaiteTarotPromptBuilder()
        let prompt = promptBuilder.buildYesNoSpread(
            question: question,
            cardNames: cardNames
        )

        // ✅ Use the currently selected Tarot service
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
        // Flip cards one by one with a delay
        for (index, card) in dealtCards.enumerated() {
            // Get image name from the card
            let imageName = getChurchOfLightImageName(card)

            // Delay flipping each card by 0.5 seconds * index
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) { [weak self] in
                guard let self = self else { return }

                // Perform flip animation
                UIView.transition(with: self.cardViews[index], duration: 0.5, options: .transitionFlipFromLeft, animations: {
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
        // Flip cards one by one with a delay
        for (index, card) in dealtRiderWaiteCards.enumerated() {
            // Get image name from the card
            let imageName = getRiderWaiteImageName(card)

            // Delay flipping each card by 0.5 seconds * index
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) { [weak self] in
                guard let self = self else { return }

                // Perform flip animation
                UIView.transition(with: self.cardViews[index], duration: 0.5, options: .transitionFlipFromLeft, animations: {
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

    // Get image name for Church of Light card
    private func getChurchOfLightImageName(_ card: ChurchOfLightTarotCard) -> String {
        // Major Arcana naming: col_majorXX
        // Where XX is the arcanum number with leading zero if needed
        // Example: "col_major01" for The Magician

        // Minor Arcana naming: col_suitRank
        // Where suit is w=wands/scepters, c=cups, s=swords, p=pentacles/coins
        // Example: "col_w05" for Five of Wands/Scepters

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

            // Handle numbered cards (extract number)
            let numbersText = ["ace": "01", "two": "02", "three": "03", "four": "04", "five": "05",
                              "six": "06", "seven": "07", "eight": "08", "nine": "09", "ten": "10"]

            for (word, num) in numbersText {
                if normalizedName.contains(word) {
                    return "col_\(suitInitial)\(num)"
                }
            }
        }

        // Fallback for any card we couldn't categorize
        return "col_cardFront"
    }

    // Get image name for Rider-Waite card
    private func getRiderWaiteImageName(_ card: RiderWaiteTarotCard) -> String {
        // Major Arcana naming: rw_majorXX
        // Where XX is the arcanum number with leading zero if needed
        // Example: "rw_major01" for The Magician

        // Minor Arcana naming: rw_suitRank
        // Where suit is w=wands, c=cups, s=swords, p=pentacles
        // Example: "rw_w05" for Five of Wands

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

            // Handle numbered cards (extract number)
            let numbersText = ["ace": "01", "two": "02", "three": "03", "four": "04", "five": "05",
                              "six": "06", "seven": "07", "eight": "08", "nine": "09", "ten": "10"]

            for (word, num) in numbersText {
                if normalizedName.contains(word) {
                    return "rw_\(suitInitial)\(num)"
                }
            }
        }

        // Fallback for any card we couldn't categorize
        return "rw_cardFront"
    }
}
class ChurchOfLightDeckManager {
    var deck: [ChurchOfLightTarotCard] = ChurchOfLightDeckLibrary.fullDeck()

    func shuffleAndCut(times: Int = 3) {
        for _ in 0..<times {
            deck.shuffle()
        }
    }

    func deal(count: Int) -> [ChurchOfLightTarotCard] {
        let dealt = Array(deck.prefix(count))
        deck.removeFirst(min(count, deck.count))
        return dealt
    }
}

class ChurchOfLightDeckLibrary {
    static func fullDeck() -> [ChurchOfLightTarotCard] {
        let raw = ChurchOfLightTarotPromptBuilder().cardCorrespondences
        return raw.map { name, info in
            let isReversed = Bool.random()
            return ChurchOfLightTarotCard.from(dictionary: info, name: name, isReversed: isReversed)
        }
    }
}
import Foundation

// MARK: - Church of Light Tarot Prompt Builder
class ChurchOfLightTarotPromptBuilder {

    // MARK: - Properties

    // Core hermetic principles
    private let hermeticPrinciples: [String: String] = [
        "Mentalism": "The ALL is MIND; The Universe is Mental.",
        "Correspondence": "As above, so below; as below, so above.",
        "Vibration": "Nothing rests; everything moves; everything vibrates.",
        "Polarity": "Everything is Dual; everything has poles; everything has its pair of opposites.",
        "Rhythm": "Everything flows, out and in; everything has its tides; all things rise and fall.",
        "Cause and Effect": "Every Cause has its Effect; every Effect has its Cause.",
        "Gender": "Gender is in everything; everything has its Masculine and Feminine Principles."
    ]

    // Card database for Church of Light correspondences
 let cardCorrespondences: [String: [String: String]] = [
        // Major Arcana
        "The Magician": [
            "Arcanum": "I",
            "Astrological": "Mercury",
            "Hebrew": "Aleph (א)",
            "Color": "Violet",
            "Element": "",
            "Metal": "Quicksilver",
            "Divinatory": "Will, Dexterity",
            "Inner Meaning": "ACTIVITY"
        ],
        "The High Priestess": [
            "Arcanum": "II",
            "Astrological": "Virgo",
            "Hebrew": "Beth (ב)",
            "Color": "Darker Violet",
            "Element": "Earth",
            "Metal": "Jasper",
            "Divinatory": "Science",
            "Inner Meaning": "EXALTATION"
        ],
        "The Empress": [
            "Arcanum": "III",
            "Astrological": "Libra",
            "Hebrew": "Gimel (ג)",
            "Color": "Lighter Yellow",
            "Element": "Air",
            "Metal": "Diamond",
            "Divinatory": "Action, Marriage",
            "Inner Meaning": "PROPAGANDA"
        ],
        "The Emperor": [
            "Arcanum": "IV",
            "Astrological": "Scorpio",
            "Hebrew": "Daleth (ד)",
            "Color": "Darker Red",
            "Element": "Water",
            "Metal": "Topaz",
            "Divinatory": "Realization",
            "Inner Meaning": "RULERSHIP"
        ],
        "The Hierophant": [
            "Arcanum": "V",
            "Astrological": "Jupiter",
            "Hebrew": "He (ה)",
            "Color": "Purple or Indigo",
            "Element": "",
            "Metal": "Tin",
            "Divinatory": "Religion, Law",
            "Inner Meaning": "REFORMATION"
        ],
        "The Lovers": [
            "Arcanum": "VI",
            "Astrological": "Venus",
            "Hebrew": "Vau (ו)",
            "Color": "Yellow",
            "Element": "",
            "Metal": "Copper",
            "Divinatory": "Temptation",
            "Inner Meaning": "AMBITION"
        ],
        "The Chariot": [
            "Arcanum": "VII",
            "Astrological": "Sagittarius",
            "Hebrew": "Zain (ז)",
            "Color": "Lighter Purple",
            "Element": "Fire",
            "Metal": "Red Garnet",
            "Divinatory": "Victory",
            "Inner Meaning": "DEVOTION"
        ],
        "Justice": [
            "Arcanum": "VIII",
            "Astrological": "Capricorn",
            "Hebrew": "Cheth (ח)",
            "Color": "Darker Blue",
            "Element": "Earth",
            "Metal": "Onyx or Sardonyx",
            "Divinatory": "Justice, Equilibrium",
            "Inner Meaning": "EXPLORATION"
        ],
        "The Hermit": [
            "Arcanum": "IX",
            "Astrological": "Aquarius",
            "Hebrew": "Teth (ט)",
            "Color": "Lighter Blue",
            "Element": "Air",
            "Metal": "Blue Sapphire",
            "Divinatory": "Wisdom, Prudence",
            "Inner Meaning": "ILLUMINATION"
        ],
        "Wheel of Fortune": [
            "Arcanum": "X",
            "Astrological": "Uranus",
            "Hebrew": "Jod (י)",
            "Color": "Dazzling White",
            "Element": "",
            "Metal": "Uranium",
            "Divinatory": "Change of Fortune",
            "Inner Meaning": "ENTHUSIASM"
        ],
        "Strength": [
            "Arcanum": "XI",
            "Astrological": "Neptune",
            "Hebrew": "Caph (כ)",
            "Color": "Iridescence",
            "Element": "",
            "Metal": "Neptunium",
            "Divinatory": "Force, Spiritual Power",
            "Inner Meaning": "I AM"
        ],
        "The Hanged Man": [
            "Arcanum": "XII",
            "Astrological": "Pisces",
            "Hebrew": "Lamed (ל)",
            "Color": "Darker Purple",
            "Element": "Water",
            "Metal": "Peridot",
            "Divinatory": "Sacrifice, Expiation",
            "Inner Meaning": "I WILL"
        ],
        "Death": [
            "Arcanum": "XIII",
            "Astrological": "Aries",
            "Hebrew": "Mem (מ)",
            "Color": "Lighter Red",
            "Element": "Fire",
            "Metal": "Amethyst",
            "Divinatory": "Transformation, Death",
            "Inner Meaning": "I SEE"
        ],
        "Temperance": [
            "Arcanum": "XIV",
            "Astrological": "Taurus",
            "Hebrew": "Nun (נ)",
            "Color": "Darker Yellow",
            "Element": "Earth",
            "Metal": "Agate",
            "Divinatory": "Regeneration, Temperance",
            "Inner Meaning": "I BELIEVE"
        ],
        "The Devil": [
            "Arcanum": "XV",
            "Astrological": "Saturn",
            "Hebrew": "Samek (ס)",
            "Color": "Blue",
            "Element": "",
            "Metal": "Lead",
            "Divinatory": "Fatality, Black Magic",
            "Inner Meaning": "BALANCE"
        ],
        "The Tower": [
            "Arcanum": "XVI",
            "Astrological": "Mars",
            "Hebrew": "Ayin (ע)",
            "Color": "Red",
            "Element": "",
            "Metal": "Iron",
            "Divinatory": "Accident, Catastrophe",
            "Inner Meaning": "I KNOW"
        ],
        "The Star": [
            "Arcanum": "XVII",
            "Astrological": "Gemini",
            "Hebrew": "Pe (פ)",
            "Color": "Lighter Violet",
            "Element": "Air",
            "Metal": "Beryl",
            "Divinatory": "Truth, Faith, Hope",
            "Inner Meaning": "I THINK"
        ],
        "The Moon": [
            "Arcanum": "XVIII",
            "Astrological": "Cancer",
            "Hebrew": "Tzaddi (צ)",
            "Color": "Lighter Green",
            "Element": "Water",
            "Metal": "Emerald",
            "Divinatory": "Deception, False Friends",
            "Inner Meaning": "I ANALYZE"
        ],
        "The Sun": [
            "Arcanum": "XIX",
            "Astrological": "Leo",
            "Hebrew": "Qoph (ק)",
            "Color": "Lighter Orange",
            "Element": "Fire",
            "Metal": "Ruby",
            "Divinatory": "Happiness, Joy",
            "Inner Meaning": "I DESIRE"
        ],
        "Judgment": [
            "Arcanum": "XX",
            "Astrological": "Moon",
            "Hebrew": "Resh (ר)",
            "Color": "Green",
            "Element": "",
            "Metal": "Silver",
            "Divinatory": "Awakening, Resurrection",
            "Inner Meaning": "I USE"
        ],
        "The World": [
            "Arcanum": "XXI",
            "Astrological": "Sun",
            "Hebrew": "Shin (ש)",
            "Color": "Orange",
            "Element": "",
            "Metal": "Gold",
            "Divinatory": "Success, Attainment",
            "Inner Meaning": "I KNOW"
        ],
        "The Fool": [
            "Arcanum": "XXII or 0",
            "Astrological": "Pluto",
            "Hebrew": "Tau (ת)",
            "Color": "Black/Ultra Violet",
            "Element": "",
            "Metal": "Clay/Plutonium",
            "Divinatory": "Spirituality, Folly",
            "Inner Meaning": "ORGANIZATION"
        ],

        // Minor Arcana - Scepters/Wands
        "Ace of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Fiery Energy",
            "Element": "Fire",
            "Divinatory": "News of a Business Opportunity",
            "Inner Meaning": "ACTIVITY"
        ],
        "Two of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Scientific Methods",
            "Element": "Fire",
            "Divinatory": "Business Dependent Upon Scientific Methods",
            "Inner Meaning": "EXALTATION"
        ],
        "Three of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Business Partnerships",
            "Element": "Fire",
            "Divinatory": "Business Partnership",
            "Inner Meaning": "PROPAGANDA"
        ],
        "Four of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Legacy",
            "Element": "Fire",
            "Divinatory": "A Legacy",
            "Inner Meaning": "RULERSHIP"
        ],
        "Five of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Good Fortune in Business",
            "Element": "Fire",
            "Divinatory": "Good Fortune in Business",
            "Inner Meaning": "REFORMATION"
        ],
        "Six of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Music, Art, Drama",
            "Element": "Fire",
            "Divinatory": "Music, Art or Drama",
            "Inner Meaning": "AMBITION"
        ],
        "Seven of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Success in Teaching",
            "Element": "Fire",
            "Divinatory": "Success in Teaching or Publishing",
            "Inner Meaning": "DEVOTION"
        ],
        "Eight of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Political Appointment",
            "Element": "Fire",
            "Divinatory": "A Political Appointment",
            "Inner Meaning": "EXPLORATION"
        ],
        "Nine of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Wise Relationship",
            "Element": "Fire",
            "Divinatory": "A Wise and Profitable Relationship",
            "Inner Meaning": "ILLUMINATION"
        ],
        "Ten of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Invention or Discovery",
            "Element": "Fire",
            "Divinatory": "An Invention or Discovery",
            "Inner Meaning": "ENTHUSIASM"
        ],
        "King of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Fiery, Headstrong, Ambitious",
            "Element": "Fire",
            "Divinatory": "An ambitious and headstrong man",
            "Inner Meaning": "I AM"
        ],
        "Queen of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Haughty, Spirited, Ambitious",
            "Element": "Fire",
            "Divinatory": "A haughty, spirited, ambitious, and resolute woman",
            "Inner Meaning": "I WILL"
        ],
        "Youth of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Benevolent, Free, Jovial",
            "Element": "Fire",
            "Divinatory": "A benevolent, free, jovial, and quick youth",
            "Inner Meaning": "I SEE"
        ],
        "Horseman of Scepters": [
            "Suit": "Scepters (Wands)",
            "Astrological": "Thoughts of Business",
            "Element": "Fire",
            "Divinatory": "Thoughts of Business",
            "Inner Meaning": "I BELIEVE"
        ],

        // Minor Arcana - Cups
        "Ace of Cups": [
            "Suit": "Cups",
            "Astrological": "Watery Energy",
            "Element": "Water",
            "Divinatory": "Letter From a Loved One",
            "Inner Meaning": "MOODS"
        ],
        "Two of Cups": [
            "Suit": "Cups",
            "Astrological": "Love",
            "Element": "Water",
            "Divinatory": "A Work of Love",
            "Inner Meaning": "REVELATION"
        ],
        "Three of Cups": [
            "Suit": "Cups",
            "Astrological": "Marriage",
            "Element": "Water",
            "Divinatory": "Marriage for Love",
            "Inner Meaning": "RESEARCH"
        ],
        "Four of Cups": [
            "Suit": "Cups",
            "Astrological": "Family",
            "Element": "Water",
            "Divinatory": "Increase in the Family",
            "Inner Meaning": "RESOURCEFULNESS"
        ],
        "Five of Cups": [
            "Suit": "Cups",
            "Astrological": "Good Fortune in Love",
            "Element": "Water",
            "Divinatory": "Good Fortune in Love",
            "Inner Meaning": "RESPONSIBILITY"
        ],
        "Six of Cups": [
            "Suit": "Cups",
            "Astrological": "Love Affair",
            "Element": "Water",
            "Divinatory": "A Love Affair",
            "Inner Meaning": "ATTAINMENT"
        ],
        "Seven of Cups": [
            "Suit": "Cups",
            "Astrological": "Successful Change",
            "Element": "Water",
            "Divinatory": "Successful Change of Home",
            "Inner Meaning": "VERITY"
        ],
        "Eight of Cups": [
            "Suit": "Cups",
            "Astrological": "Extravagance",
            "Element": "Water",
            "Divinatory": "Extravagance",
            "Inner Meaning": "SELF-SACRIFICE"
        ],
        "Nine of Cups": [
            "Suit": "Cups",
            "Astrological": "Hopes Will Be Realized",
            "Element": "Water",
            "Divinatory": "Hopes Will Be Realized",
            "Inner Meaning": "VICISSITUDES"
        ],
        "Ten of Cups": [
            "Suit": "Cups",
            "Astrological": "Unconventional Affection",
            "Element": "Water",
            "Divinatory": "A decidedly unconventional affectional interest",
            "Inner Meaning": "EMOTION"
        ],
        "King of Cups": [
            "Suit": "Cups",
            "Astrological": "Mild, Reserved, Home-Loving",
            "Element": "Water",
            "Divinatory": "A mild, reserved, home-loving man",
            "Inner Meaning": "I FEEL"
        ],
        "Queen of Cups": [
            "Suit": "Cups",
            "Astrological": "Active, Selfish, Proud",
            "Element": "Water",
            "Divinatory": "An active, selfish, proud, and resentful woman",
            "Inner Meaning": "I DESIRE"
        ],
        "Youth of Cups": [
            "Suit": "Cups",
            "Astrological": "Negative, Timid, Harmless",
            "Element": "Water",
            "Divinatory": "A negative, timid, listless, and harmless youth",
            "Inner Meaning": "I BELIEVE"
        ],
        "Horseman of Cups": [
            "Suit": "Cups",
            "Astrological": "Thoughts of Love",
            "Element": "Water",
            "Divinatory": "Thoughts of Love and Affection",
            "Inner Meaning": "EMOTION"
        ],

        // Minor Arcana - Coins/Pentacles
        "Ace of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Earthy Energy",
            "Element": "Air",
            "Divinatory": "A Short Journey",
            "Inner Meaning": "POLICY"
        ],
        "Two of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Labor",
            "Element": "Air",
            "Divinatory": "Money Acquired by Hard Labor",
            "Inner Meaning": "INDEPENDENCE"
        ],
        "Three of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Money Marriage",
            "Element": "Air",
            "Divinatory": "Marriage for Money",
            "Inner Meaning": "EXPIATION"
        ],
        "Four of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Money Through Partner",
            "Element": "Air",
            "Divinatory": "Money Received Through a Partner",
            "Inner Meaning": "ORIGINALITY"
        ],
        "Five of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Abundant Wealth",
            "Element": "Air",
            "Divinatory": "Abundant Wealth",
            "Inner Meaning": "INSPIRATION"
        ],
        "Six of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Social Event",
            "Element": "Air",
            "Divinatory": "A Social Event",
            "Inner Meaning": "REPRESSION"
        ],
        "Seven of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Money Through Journey",
            "Element": "Air",
            "Divinatory": "Money Earned Through a Journey",
            "Inner Meaning": "INTUITION"
        ],
        "Eight of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Law Suit",
            "Element": "Air",
            "Divinatory": "A Costly Law Suit",
            "Inner Meaning": "FIDELITY"
        ],
        "Nine of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Money Spent on Associates",
            "Element": "Air",
            "Divinatory": "Money Spent on Associates",
            "Inner Meaning": "REASON"
        ],
        "Ten of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Financial Loss and Gain",
            "Element": "Air",
            "Divinatory": "Alternate Financial Loss and Gain",
            "Inner Meaning": "ASPIRATION"
        ],
        "King of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Intelligent, Restless, Fickle",
            "Element": "Air",
            "Divinatory": "An intelligent, restless, and fickle man",
            "Inner Meaning": "I THINK"
        ],
        "Queen of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Good, High-Minded, Noble",
            "Element": "Air",
            "Divinatory": "A good, high-minded, noble, and amiable woman",
            "Inner Meaning": "BALANCE"
        ],
        "Youth of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Witty, Argumentative, Refined",
            "Element": "Air",
            "Divinatory": "A witty, argumentative, and refined youth",
            "Inner Meaning": "I KNOW"
        ],
        "Horseman of Coins": [
            "Suit": "Coins (Pentacles)",
            "Astrological": "Thoughts of Money",
            "Element": "Air",
            "Divinatory": "Thoughts of Health, Money, and Business",
            "Inner Meaning": "ASPIRATION"
        ],

        // Minor Arcana - Swords
        "Ace of Swords": [
            "Suit": "Swords",
            "Astrological": "Airy Energy",
            "Element": "Earth",
            "Divinatory": "News of Sickness or Death",
            "Inner Meaning": "ORGANIZATION"
        ],
        "Two of Swords": [
            "Suit": "Swords",
            "Astrological": "Sickness",
            "Element": "Earth",
            "Divinatory": "Sickness Through Overwork",
            "Inner Meaning": "MARTYRDOM"
        ],
        "Three of Swords": [
            "Suit": "Swords",
            "Astrological": "Lawsuit or Divorce",
            "Element": "Earth",
            "Divinatory": "Lawsuit or Divorce",
            "Inner Meaning": "IDEALISM"
        ],
        "Four of Swords": [
            "Suit": "Swords",
            "Astrological": "Remorse",
            "Element": "Earth",
            "Divinatory": "Remorse for Past Action",
            "Inner Meaning": "DETERMINATION"
        ],
        "Five of Swords": [
            "Suit": "Swords",
            "Astrological": "Escape from Danger",
            "Element": "Earth",
            "Divinatory": "Escape from Danger",
            "Inner Meaning": "STRUGGLE"
        ],
        "Six of Swords": [
            "Suit": "Swords",
            "Astrological": "Dissipation",
            "Element": "Earth",
            "Divinatory": "Dissipation",
            "Inner Meaning": "MASTERSHIP"
        ],
        "Seven of Swords": [
            "Suit": "Swords",
            "Astrological": "Danger Through Travel",
            "Element": "Earth",
            "Divinatory": "Danger Through Travel or Sport",
            "Inner Meaning": "ACHIEVEMENT"
        ],
        "Eight of Swords": [
            "Suit": "Swords",
            "Astrological": "Loss of Honor",
            "Element": "Earth",
            "Divinatory": "Loss of Honor or Business Failure",
            "Inner Meaning": "EXPERIENCE"
        ],
        "Nine of Swords": [
            "Suit": "Swords",
            "Astrological": "Quarrel",
            "Element": "Earth",
            "Divinatory": "Quarrel Resulting in Enmity",
            "Inner Meaning": "RENUNCIATION"
        ],
        "Ten of Swords": [
            "Suit": "Swords",
            "Astrological": "Sudden Loss",
            "Element": "Earth",
            "Divinatory": "Sudden Loss of Employment",
            "Inner Meaning": "PRACTICALITY"
        ],
        "King of Swords": [
            "Suit": "Swords",
            "Astrological": "Reserved, Sullen, Practical",
            "Element": "Earth",
            "Divinatory": "A reserved, sullen, and practical man",
            "Inner Meaning": "I HAVE"
        ],
        "Queen of Swords": [
            "Suit": "Swords",
            "Astrological": "Studious, Even-Tempered",
            "Element": "Earth",
            "Divinatory": "A studious, even-tempered, and ingenious woman",
            "Inner Meaning": "I ANALYZE"
        ],
        "Youth of Swords": [
            "Suit": "Swords",
            "Astrological": "Crafty, Selfish, Avaricious",
            "Element": "Earth",
            "Divinatory": "A crafty, selfish, reserved, and avaricious youth",
            "Inner Meaning": "I USE"
        ],
        "Horseman of Swords": [
            "Suit": "Swords",
            "Astrological": "Thoughts of Strife",
            "Element": "Earth",
            "Divinatory": "Thoughts of Strife or Sickness",
            "Inner Meaning": "PRACTICALITY"
        ]
    ]

    // MARK: - Methods
    /// Function to build a prompt for a 5-card Yes/No spread
    /// Function to build a prompt for a 5-card Yes/No spread
    func buildYesNoSpread(question: String, cardNames: [String]) -> String {
        // Validate we have exactly 5 cards
        guard cardNames.count == 5 else {
            return "Error: Yes/No spread requires exactly 5 cards."
        }

        // Define positions for 5-card yes/no spread (right to left)
        let positions = ["Distant Past", "Recent Past", "Present", "Near Future", "Distant Future"]

        // Calculate yes/no score
        var yesNoScore = 0
        var cardOrientations: [Bool] = [] // true = upright, false = reversed

        for (index, cardName) in cardNames.enumerated() {
            let isReversed = cardName.lowercased().contains("reversed")
            cardOrientations.append(!isReversed)

            // Middle card (Present) is worth 2 points
            if index == 2 {
                yesNoScore += isReversed ? -2 : 2
            } else {
                yesNoScore += isReversed ? -1 : 1
            }
        }

        // Determine overall answer
        let overallAnswer: String
        if yesNoScore > 0 {
            overallAnswer = "Yes"
        } else if yesNoScore < 0 {
            overallAnswer = "No"
        } else {
            overallAnswer = "Maybe"
        }

        // Start building the prompt
        var prompt = """
        # HERMETIC YES/NO TAROT READING
        
        ## Question
        "\(question)"
        
        ## Spread
        Five-Card Yes/No Spread (read right to left)
        
        ## Cards in Position
        
        """

        // Add each card with detailed correspondences
        for (index, cardName) in cardNames.enumerated() {
            let position = positions[index]
            let normalizedCardName = normalizeCardName(cardName)
            let isReversed = cardName.lowercased().contains("reversed")

            // Add position and card information
            prompt += """
            
            ### Position \(index + 1): \(position)
            Card: \(cardName)
            
            """

            // Add correspondences if available
            if let cardInfo = cardCorrespondences[normalizedCardName] {
                prompt += "**Church of Light Correspondences:**\n"

                // Add astrological correspondence (primary focus as requested)
                if let astrological = cardInfo["Astrological"] {
                    prompt += "- Astrological: \(astrological)\n"
                }

                // Include court card zodiac correspondences if applicable
                if normalizedCardName.contains("King of") ||
                   normalizedCardName.contains("Queen of") ||
                   normalizedCardName.contains("Youth of") {

                    let zodiacSign = getCourtCardZodiacSign(normalizedCardName)
                    prompt += "- Zodiac Sign: \(zodiacSign)\n"

                    // Add information about reversed court cards representing opposite gender
                    if isReversed {
                        prompt += "- Represents: Person of opposite sex with \(zodiacSign) qualities\n"
                    } else {
                        prompt += "- Represents: Person with \(zodiacSign) qualities\n"
                    }
                }

                // Add orientation value for yes/no calculation
                if index == 2 { // Middle card
                    prompt += "- Yes/No Value: \(isReversed ? "-2 (No)" : "+2 (Yes)")\n"
                } else {
                    prompt += "- Yes/No Value: \(isReversed ? "-1 (No)" : "+1 (Yes)")\n"
                }
            }
        }

        // Add numeric score (but don't reveal overall answer yet)
        prompt += """
        
        ## Yes/No Calculation
        Total score: \(yesNoScore)
        
        ## Interpretation Guidelines
        
        Please provide a Church of Light hermetic interpretation of this Yes/No spread that:
        
        1. **Tells the story revealed by the cards** through a narrative that flows from distant past to distant future:
           - Begin with a compelling introduction that sets the cosmic stage for the question
           - Weave together the astrological influences into a cohesive narrative
           - Adapt the interpretation to the specific context of the question (sports, relationships, career, etc.)
           - Explain what each card reveals about the querent's journey
           
        2. **Card-by-Card Interpretation** within the narrative:
           - Focus primarily on each card's astrological correspondence
           - For court cards, identify the specific zodiac sign influences and if reversed, note the person is of the opposite gender
           - Explain how each card's energy manifests in the specific context of the question
           
        3. **Highlight Astrological Patterns**:
           - Which planets or signs predominate?
           - How these cosmic forces are shaping the querent's circumstances
           
        4. **Conclude with the answer**: Only at the end, reveal whether the answer is Yes, No, or Maybe, tying this conclusion to the narrative you've presented.
        
        Keep your interpretation dignified while adapting to the specific context of the question. Remember that "the stars impel, they do not compel" - emphasize the querent's free will in working with these cosmic forces.
        """

        return prompt
    }

    /// Helper function to get zodiac sign for court cards
    private func getCourtCardZodiacSign(_ cardName: String) -> String {
        if cardName.contains("King of Scepters") { return "Aries" }
        else if cardName.contains("King of Swords") { return "Taurus" }
        else if cardName.contains("King of Coins") { return "Gemini" }
        else if cardName.contains("King of Cups") { return "Cancer" }
        else if cardName.contains("Queen of Scepters") { return "Leo" }
        else if cardName.contains("Queen of Swords") { return "Virgo" }
        else if cardName.contains("Queen of Coins") { return "Libra" }
        else if cardName.contains("Queen of Cups") { return "Scorpio" }
        else if cardName.contains("Youth of Scepters") { return "Sagittarius" }
        else if cardName.contains("Youth of Swords") { return "Capricorn" }
        else if cardName.contains("Youth of Coins") { return "Aquarius" }
        else if cardName.contains("Youth of Cups") { return "Pisces" }
        else { return "Unknown" }
    }
    /// Builds a comprehensive tarot reading prompt for the AI model based on Church of Light principles
    func buildPrompt(question: String, spreadName: String, cardNames: [String]) -> String {
        // Get spread positions based on the spread name
        let positions = getPositionsForSpread(spreadName: spreadName, cardCount: cardNames.count)

        // Start with the system context
        var prompt = """
        # HERMETIC TAROT READING REQUEST
        
        ## Question
        "\(question)"
        
        ## Spread
        \(spreadName) Spread
        
        ## Cards in Position
        
        """

        // Add each card with detailed correspondences
        for (index, cardName) in cardNames.enumerated() {
            if index < positions.count {
                let position = positions[index]
                let normalizedCardName = normalizeCardName(cardName)
                let isReversed = cardName.lowercased().contains("reversed")

                // Add position and card information
                prompt += """
                
                ### Position \(index + 1): \(position)
                Card: \(cardName)
                
                """

                // Add correspondences if available
                if let cardInfo = cardCorrespondences[normalizedCardName] {
                    prompt += "**Church of Light Correspondences:**\n"

                    if let arcanum = cardInfo["Arcanum"] {
                        prompt += "- Arcanum: \(arcanum)\n"
                    }

                    if let astrological = cardInfo["Astrological"] {
                        prompt += "- Astrological: \(astrological)\n"
                    }

                    if let hebrew = cardInfo["Hebrew"] {
                        prompt += "- Hebrew Letter: \(hebrew)\n"
                    }

                    if let color = cardInfo["Color"] {
                        prompt += "- Color: \(color)\n"
                    }

                    if let element = cardInfo["Element"] {
                        prompt += "- Element: \(element)\n"
                    }

                    if let metal = cardInfo["Metal"] {
                        prompt += "- Gem/Metal: \(metal)\n"
                    }

                    if let divinatory = cardInfo["Divinatory"] {
                        prompt += "- Divinatory Significance: \(divinatory)\n"
                    }

                    if let innerMeaning = cardInfo["Inner Meaning"] {
                        prompt += "- Inner Meaning: \(innerMeaning)\n"
                    }

                    // Add reversed meaning note if applicable
                    if isReversed {
                        prompt += "- Orientation: Reversed (energy blocked, inverted, or internalized)\n"
                    } else {
                        prompt += "- Orientation: Upright\n"
                    }
                }
            }
        }

        // Add instructions for interpretation
        prompt += """
        
        ## Interpretation Guidelines
        
        Please provide a Church of Light hermetic tarot interpretation that includes:
        
        1. **Introduction**: Connect the question to the hermetic principles involved
        
        2. **Individual Card Analysis**: For each card, explain:
           - Its specific Church of Light correspondences (astrological, numerical, elemental)
           - The spiritual vibration it represents in its position
           - Its relation to the Hebrew letter and cosmic principle
        
        3. **Spread Pattern Analysis**: Analyze the pattern of:
           - Elements (predominance of Fire, Water, Air, Earth)
           - Astrological influences (planets and signs)
           - Inner Meaning patterns revealed across the spread
        
        4. **Hermetic Synthesis**: Explain how the cards together reveal the operation of hermetic laws:
           - Which hermetic principles are most active (Mentalism, Correspondence, etc.)
           - How the cards show "as above, so below" in the querent's life
           - The spiritual evolution indicated by the spread
        
        5. **Spiritual Guidance**: Offer practical guidance that:
           - Emphasizes the querent's agency and free will
           - Shows how to align with positive cosmic forces
           - Provides specific spiritual practices aligned with the cards
        
        Your interpretation should be dignified and illuminating, focusing on spiritual evolution rather than prediction, and should reflect The Church of Light's teaching that "the stars impel, they do not compel."
        """

        return prompt
    }

    /// Normalizes a card name by removing "reversed" and standardizing formatting
    private func normalizeCardName(_ cardName: String) -> String {
        let name = cardName.replacingOccurrences(of: " (Reversed)", with: "")
                           .replacingOccurrences(of: " reversed", with: "")
                           .trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle potential variations in naming
        if name.lowercased().contains("king of wands") {
            return "King of Scepters"
        } else if name.lowercased().contains("queen of wands") {
            return "Queen of Scepters"
        } else if name.lowercased().contains("knight of wands") || name.lowercased().contains("horseman of wands") {
            return "Horseman of Scepters"
        } else if name.lowercased().contains("page of wands") || name.lowercased().contains("youth of wands") {
            return "Youth of Scepters"
        }
        // Add similar conversions for other suits

        return name
    }

    /// Gets the appropriate positions for a spread
    private func getPositionsForSpread(spreadName: String, cardCount: Int) -> [String] {
        switch spreadName.lowercased() {
        case "celtic cross":
            return [
                "The Present", "The Challenge", "Foundation", "Recent Past",
                "Possible Outcome", "Immediate Future", "The Self", "External Influences",
                "Hopes & Fears", "Final Outcome"
            ]
        case "three card":
            return ["Past", "Present", "Future"]
        case "spiritual cross":
            return ["Material Plane", "Spiritual Plane", "Path to Follow", "Outcome"]
        case "planetary spread":
            return ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn"]
        case "hermetic square":
            return ["Material", "Mental", "Emotional", "Spiritual"]
        default:
            // Generate generic positions if spread not recognized
            return (0..<cardCount).map { "Position \($0 + 1)" }
        }
    }

    /// Gets the system instructions for the AI model
    func getSystemInstructions() -> String {
        return """
        You are a master hermetician and tarot interpreter from The Church of Light, trained in the Brotherhood of Light Egyptian Tarot system as taught by C.C. Zain. Your interpretations are based on the sacred science of correspondences between cards, astrological forces, Hebrew letters, and universal principles.

        Follow these principles in your interpretation:

        1. HERMETIC FOUNDATION: Each card represents a specific spiritual vibration with precise correspondences. The cards reveal universal laws operating in the querent's life.

        2. SPIRITUAL FOCUS: Focus on spiritual development, character building, and soul evolution rather than fortune-telling or prediction.

        3. ASTROLOGICAL BASIS: Every card has specific astrological correspondences that connect it to cosmic forces. These determine the card's core meaning.

        4. INNER MEANING: Each card has an "inner meaning" that reveals its spiritual essence beyond its mundane significance.

        5. AGENCY & RESPONSIBILITY: Emphasize that "the stars impel, they do not compel" - cosmic forces influence but do not determine outcomes.

        6. EDUCATIONAL APPROACH: Your reading should educate the querent about sacred principles while providing practical guidance.

        7. SPIRITUAL DIGNITY: Maintain a tone of spiritual dignity, wisdom, and clarity befitting a Church of Light minister.

        Your interpretation should help the querent understand the spiritual forces operating in their life and how to consciously cooperate with these forces to advance their soul's evolution.
        """
    }
}

// MARK: - Example Usage

/*
// Initialize the prompt builder
let promptBuilder = ChurchOfLightTarotPromptBuilder()

// Generate a prompt for a reading
let prompt = promptBuilder.buildPrompt(
    question: "What spiritual lessons should I focus on during this phase of my life?",
    spreadName: "Three Card",
    cardNames: ["The Magician", "The Tower (Reversed)", "The Star"]
)

print(prompt)
*/
import Foundation

class HuggingFaceTarotService: TarotAIService {
    private let baseURL = "https://api-inference.huggingface.co/models/"
    private let model: String
    private let apiKey: String

    init(apiKey: String = APIKeys.huggingFace,
         model: String = "mistralai/Mistral-7B-Instruct-v0.2") {
        self.apiKey = apiKey
        self.model = model
    }

    func generateTarotReading(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let endpoint = URL(string: baseURL + model) else {
            completion(.failure(NSError(domain: "HuggingFaceTarotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid model URL"])))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["inputs": prompt]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.logResponse(data: data, response: response, error: error, label: "HuggingFace")

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "HuggingFaceTarotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let result = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let text = result.first?["generated_text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "HuggingFaceTarotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format."])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func logResponse(data: Data?, response: URLResponse?, error: Error?, label: String) {
        print("🔍 [\(label)] Tarot API Response Debug")

        if let error = error {
            print("❌ [\(label)] Error: \(error.localizedDescription)")
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 [\(label)] HTTP Status: \(httpResponse.statusCode)")
            print("📋 [\(label)] Headers: \(httpResponse.allHeaderFields)")
        }

        if let data = data, let bodyString = String(data: data, encoding: .utf8) {
            print("📨 [\(label)] Body:\n\(bodyString)")
        } else {
            print("⚠️ [\(label)] No body received.")
        }

        print("––––––––––––––––––––––––––––––")
    }
}

class OpenAITarotService: TarotAIService {
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let apiKey = APIKeys.openAI
    private let model = "gpt-4o"

    func generateTarotReading(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": ChurchOfLightTarotPromptBuilder().getSystemInstructions()],
                ["role": "user", "content": prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.logResponse(data: data, response: response, error: error, label: "OpenAI")

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAITarotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "OpenAITarotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Malformed response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func logResponse(data: Data?, response: URLResponse?, error: Error?, label: String) {
        print("🔍 [\(label)] Tarot API Response Debug")
        if let error = error { print("❌ Error: \(error.localizedDescription)") }
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status: \(httpResponse.statusCode)")
            print("📋 Headers: \(httpResponse.allHeaderFields)")
        }
        if let data = data, let bodyString = String(data: data, encoding: .utf8) {
            print("📨 Body:\n\(bodyString)")
        } else {
            print("⚠️ No body received.")
        }
        print("––––––––––––––––––––––––––––––")
    }
}

import Foundation

class ClaudeTarotService: TarotAIService {
    let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    let apiKey = APIKeys.anthropic

    func generateTarotReading(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        // Change this line - use x-api-key instead of Authorization
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-3-7-sonnet-20250219",
            "max_tokens": 1024,
            "messages": [["role": "user", "content": prompt]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.logResponse(data: data, response: response, error: error, label: "Claude")

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "ClaudeTarotService", code: -1)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Try to handle API error responses
                    if let errorInfo = json["error"] as? [String: Any],
                       let errorMessage = errorInfo["message"] as? String {
                        completion(.failure(NSError(
                            domain: "ClaudeTarotService",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )))
                        return
                    }

                    // Parse content in the same way it works in your other services
                    if let content = json["content"] as? [[String: Any]] {
                        let texts = content.compactMap { item -> String? in
                            if let text = item["text"] as? String {
                                return text
                            }
                            return nil
                        }.joined()

                        if !texts.isEmpty {
                            completion(.success(texts))
                        } else {
                            completion(.failure(NSError(domain: "ClaudeTarotService", code: -3)))
                        }
                    } else {
                        completion(.failure(NSError(domain: "ClaudeTarotService", code: -4)))
                    }
                } else {
                    completion(.failure(NSError(domain: "ClaudeTarotService", code: -5)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Keep your existing logResponse method
    private func logResponse(data: Data?, response: URLResponse?, error: Error?, label: String) {
        // ...existing implementation...
    }
}

protocol TarotAIService {
    func generateTarotReading(prompt: String, completion: @escaping (Result<String, Error>) -> Void)
}

class TarotAIServiceManager {
    static let shared = TarotAIServiceManager()

    enum Provider: String, CaseIterable {
        case openAI = "OpenAI"
        case huggingFace = "HuggingFace"
        case claude = "Claude"
    }

    var currentProvider: Provider = .openAI {
        didSet {
            switch currentProvider {
            case .openAI:
                currentService = OpenAITarotService()
            case .huggingFace:
                currentService = HuggingFaceTarotService()
            case .claude:
                currentService = ClaudeTarotService()
            }
        }
    }

    var currentService: TarotAIService = OpenAITarotService()

    private init() {}
}
import UIKit

class TarotSettingsViewController: UIViewController {
    let segmentedControl = UISegmentedControl(items: TarotAIServiceManager.Provider.allCases.map { $0.rawValue })

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupSegmentedControl()
    }

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = TarotAIServiceManager.Provider.allCases.firstIndex(of: TarotAIServiceManager.shared.currentProvider) ?? 0
        segmentedControl.addTarget(self, action: #selector(serviceChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func serviceChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        if TarotAIServiceManager.Provider.allCases.indices.contains(selectedIndex) {
            let newProvider = TarotAIServiceManager.Provider.allCases[selectedIndex]
            TarotAIServiceManager.shared.currentProvider = newProvider
        }
    }

}


// RiderWaiteTarotCard struct
struct RiderWaiteTarotCard: Identifiable {
    let id = UUID()
    let name: String
    let arcanum: String?
    let element: String?
    let astrological: String?
    let keywords: String?
    let meaning: String?
    let reversedMeaning: String?
    let suit: String?
    let isReversed: Bool

    static func from(dictionary: [String: String], name: String, isReversed: Bool = false) -> RiderWaiteTarotCard {
        return RiderWaiteTarotCard(
            name: name,
            arcanum: dictionary["Arcanum"],
            element: dictionary["Element"],
            astrological: dictionary["Astrological"],
            keywords: dictionary["Keywords"],
            meaning: dictionary["Meaning"],
            reversedMeaning: dictionary["Reversed"],
            suit: dictionary["Suit"],
            isReversed: isReversed
        )
    }
}

// RiderWaiteDeckManager class
class RiderWaiteDeckManager {
    var deck: [RiderWaiteTarotCard] = []

    // Dictionary of Rider-Waite card correspondences
    let cardCorrespondences: [String: [String: String]] = [
        // Major Arcana
        "The Fool": [
            "Arcanum": "0",
            "Element": "Air",
            "Astrological": "Uranus",
            "Keywords": "Beginnings, innocence, spontaneity, freedom",
            "Meaning": "New beginnings, faith in the universe, innocence, spontaneity",
            "Reversed": "Recklessness, risk-taking, inconsideration"
        ],
        "The Magician": [
            "Arcanum": "1",
            "Element": "Air",
            "Astrological": "Mercury",
            "Keywords": "Manifestation, power, action, resourcefulness",
            "Meaning": "Manifestation, resourcefulness, power, inspired action",
            "Reversed": "Manipulation, poor planning, untapped talents"
        ],
        // Add remaining cards here
    ]

    init() {
        createDeck()
    }

    private func createDeck() {
        deck = []

        // Add all cards from correspondences
        for (cardName, attributes) in cardCorrespondences {
            let isReversed = Bool.random() // 50% chance of being reversed
            let card = RiderWaiteTarotCard.from(dictionary: attributes, name: cardName, isReversed: isReversed)
            deck.append(card)
        }
    }

    func shuffleAndCut() {
        deck.shuffle()
        // Simulate cutting the deck
        let cutPoint = Int.random(in: 10...(deck.count - 10))
        let topPortion = Array(deck[0..<cutPoint])
        let bottomPortion = Array(deck[cutPoint..<deck.count])
        deck = bottomPortion + topPortion
    }
}

// RiderWaiteTarotPromptBuilder class - simplified approach
class RiderWaiteTarotPromptBuilder {
    // Function to build a 5-card Yes/No spread for Rider-Waite
    func buildYesNoSpread(question: String, cardNames: [String]) -> String {
        // Validate we have exactly 5 cards
        guard cardNames.count == 5 else {
            return "Error: Yes/No spread requires exactly 5 cards."
        }

        // Define positions for 5-card yes/no spread (right to left)
        let positions = ["Distant Past", "Recent Past", "Present", "Near Future", "Distant Future"]

        // Calculate yes/no score
        var yesNoScore = 0

        for (index, cardName) in cardNames.enumerated() {
            let isReversed = cardName.lowercased().contains("reversed")

            // Middle card (Present) is worth 2 points
            if index == 2 {
                yesNoScore += isReversed ? -2 : 2
            } else {
                yesNoScore += isReversed ? -1 : 1
            }
        }

        // Start building the prompt
        var prompt = """
        # RIDER-WAITE TAROT YES/NO READING
        
        ## Question
        "\(question)"
        
        ## Spread
        Five-Card Yes/No Spread (read right to left)
        
        ## Cards in Position
        
        """

        // Add each card with its position and orientation
        for (index, cardName) in cardNames.enumerated() {
            let position = positions[index]
            let isReversed = cardName.lowercased().contains("reversed")

            // Add position and card information
            prompt += """
            
            ### Position \(index + 1): \(position)
            Card: \(cardName)
            
            """

            // Add orientation value for yes/no calculation
            if index == 2 { // Middle card
                prompt += "Yes/No Value: \(isReversed ? "-2 (No)" : "+2 (Yes)")\n"
            } else {
                prompt += "Yes/No Value: \(isReversed ? "-1 (No)" : "+1 (Yes)")\n"
            }
        }

        // Add numeric score (but don't reveal overall answer yet)
        prompt += """
        
        ## Yes/No Calculation
        Total score: \(yesNoScore)
        
        ## Interpretation Guidelines
        
        Please provide a Rider-Waite tarot interpretation of this Yes/No spread that:
        
        1. **Tells the story revealed by the cards** through a narrative that flows from distant past to distant future:
           - Begin with a compelling introduction that sets the stage for the question
           - Weave together the influences into a cohesive narrative
           - Adapt the interpretation to the specific context of the question (sports, relationships, career, etc.)
           - Explain what each card reveals about the querent's journey
           
        2. **Card-by-Card Interpretation** within the narrative:
           - Focus on the traditional Rider-Waite meanings of each card
           - Explain how each card's meaning manifests in the specific context of the question
           - Consider both upright and reversed meanings
           
        3. **Highlight Element and Astrological Patterns**:
           - Which elements or astrological influences predominate?
           - How these forces are shaping the querent's circumstances
           
        4. **Integrate the narrative** with the spread positions to show how past influences lead to future outcomes
        
        5. **Conclude with the answer**: At the end of your interpretation, provide the final Yes, No, or Maybe answer based on the calculated score and the overall energy of the reading.
        
        Keep your interpretation clear and accessible, balancing traditional tarot wisdom with practical insights relevant to the question.
        """

        return prompt
    }

    // Helper to normalize card names
    private func normalizeCardName(_ cardName: String) -> String {
        return cardName.replacingOccurrences(of: " (Reversed)", with: "")
                      .replacingOccurrences(of: " reversed", with: "")
                      .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
