//
//  Tarot.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/12/25.
//

import Foundation
//
//  Taroter.swift
//  AstroLogic
//
//  Created by Errick Williams on 4/12/25.
//

import Foundation
import UIKit

class YesNoTarotViewController: UIViewController {
    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let cardViews = [UIView(), UIView(), UIView(), UIView(), UIView()]
    private let resultLabel = UILabel()

    private var deckManager = TarotDeckManager()
    private var question: String = ""
    private var dealtCards: [TarotCards] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        questionField.placeholder = "Enter your yes/no question"
        questionField.borderStyle = .roundedRect
        questionField.translatesAutoresizingMaskIntoConstraints = false

        askButton.setTitle("Ask the Cards", for: .normal)
        askButton.addTarget(self, action: #selector(handleAsk), for: .touchUpInside)
        askButton.translatesAutoresizingMaskIntoConstraints = false

        resultLabel.textAlignment = .center
        resultLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(questionField)
        view.addSubview(askButton)
        view.addSubview(resultLabel)

        for (i, cardView) in cardViews.enumerated() {
            cardView.backgroundColor = .systemBlue
            cardView.layer.cornerRadius = 8
            cardView.tag = i
            cardView.isUserInteractionEnabled = true
            cardView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cardView)
        }

        NSLayoutConstraint.activate([
            questionField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 12),
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            resultLabel.topAnchor.constraint(equalTo: askButton.bottomAnchor, constant: 180),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

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

        deckManager = TarotDeckManager()
        deckManager.shuffleAndCut()
        dealtCards = Array(deckManager.deck.prefix(5))


        resultLabel.text = "Reading..."
        interpretYesNo()
    }

    private func interpretYesNo() {
        guard dealtCards.count == 5 else {
            print("❌ Error: You must have exactly 5 cards. Current count: \(dealtCards.count)")
            resultLabel.text = "Error: Not enough cards."
            return
        }

        // Debug: Card status
        for (i, card) in dealtCards.enumerated() {
            print("🃏 Card \(i + 1): \(card.name) \(card.isReversed ? "(Reversed)" : "(Upright)")")
        }

        let cardNames = dealtCards.map { $0.name + ($0.isReversed ? " (Reversed)" : "") }

        let prompt = """
        You are Lila, a Tarot reader trained in the Sacred Tarot tradition of the Church of Light.
        
        The querent has asked a YES or NO question:
        \"\(question)\"
        
        You are using the Sacred Tarot Yes/No method. Five cards have been drawn and are read from **right to left**:
        
        - **Card 1 (Far Right / Past)**: \(cardNames[0])
        - **Card 2**: \(cardNames[1])
        - **Card 3 (Center / Present – counts as 2 points)**: \(cardNames[2])
        - **Card 4**: \(cardNames[3])
        - **Card 5 (Far Left / Future)**: \(cardNames[4])
        
        **Instructions:**
        
        1. Count **Upright** cards as **YES**, and **Reversed** cards as **NO**.
        2. The **center card (Card 3)** counts **twice** in the scoring.
        3. Tally the YES and NO points and provide the total.
        
        **Decision Rules:**
        
        - If YES points > NO points → The answer is **YES**.
        - If NO points > YES points → The answer is **NO**.
        - If YES points = NO points → The answer is **MAYBE**.
        
        Then provide a **brief interpretation** of each card in its position (Past to Future). Emphasize what each card suggests about the context, factors at play, or outcome, not just its upright/reversed meaning.
        
        Finally, provide a **summary** of what additional insight the spread offers about the question. Reflect on spiritual principles if appropriate.
        
        Remember: You are not just predicting events. You are offering insight rooted in Hermetic philosophy. Speak clearly, encouraging inner discernment, not fatalism.
        """

        // Debug: Log the full prompt
        print("📦 Full prompt sent to AI:\n\(prompt)")

        // Debug: Notify when AI request begins
        print("🧠 Sending prompt to AIServiceManager...")
        print("🧭 Current AI Service: \(type(of: AIServiceManager.shared.currentService))")

        AIServiceManager.shared.currentService.generateResponse(
            prompt: prompt,
            chartCake: nil,
            otherChart: nil,
            transitDate: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let answer):
                    self?.resultLabel.text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                case .failure:
                    self?.resultLabel.text = "Unable to interpret the cards."
                }
            }
        }
    }

}
class TarotDeckManager {
    var deck: [TarotCards] = TarotCardLibrary.fullDeck()
    var dealtCards: [TarotCards] = []

    func shuffleAndCut(times: Int = 3) {
        for _ in 0..<times {
            deck.shuffle()
        }
    }

    func deal(count: Int) -> [TarotCards] {
        dealtCards = Array(deck.prefix(count))
        deck.removeFirst(min(count, deck.count))
        return dealtCards
    }
}

import Foundation

struct TarotCards: Identifiable {
    let id = UUID()
    let name: String
    let arcanum: String
    let astrological: String
    let hebrew: String
    let color: String
    let element: String
    let divinatory: String
    let meaning: String
    let isReversed: Bool
}

class TarotCardLibrary {
    static func fullDeck() -> [TarotCards] {
        return [
            TarotCards(name: "The Magician", arcanum: "I", astrological: "Mercury", hebrew: "Aleph", color: "Violet", element: "Air", divinatory: "Will, Dexterity", meaning: "Initiative, skill, ability to accomplish", isReversed: false),
            TarotCards(name: "The High Priestess", arcanum: "II", astrological: "Virgo", hebrew: "Beth", color: "Darker Violet", element: "Earth", divinatory: "Science", meaning: "Intuition, inner wisdom, hidden knowledge", isReversed: false),
            TarotCards(name: "The Empress", arcanum: "III", astrological: "Libra", hebrew: "Gimel", color: "Lighter Yellow", element: "Air", divinatory: "Action, Marriage", meaning: "Fertility, abundance, creative expression", isReversed: false),
            TarotCards(name: "The Emperor", arcanum: "IV", astrological: "Scorpio", hebrew: "Daleth", color: "Darker Red", element: "Water", divinatory: "Realization", meaning: "Authority, stability, leadership", isReversed: false),
            TarotCards(name: "The Hierophant", arcanum: "V", astrological: "Jupiter", hebrew: "He", color: "Purple or Indigo", element: "Fire", divinatory: "Religion, Law", meaning: "Spiritual wisdom, tradition, education", isReversed: false),
            TarotCards(name: "The Lovers", arcanum: "VI", astrological: "Venus", hebrew: "Vau", color: "Yellow", element: "Air", divinatory: "Temptation", meaning: "Choice, harmony, relationships", isReversed: false),
            TarotCards(name: "The Chariot", arcanum: "VII", astrological: "Sagittarius", hebrew: "Zain", color: "Lighter Purple", element: "Fire", divinatory: "Victory", meaning: "Triumph, willpower, determination", isReversed: false),
            TarotCards(name: "Strength", arcanum: "VIII", astrological: "Capricorn", hebrew: "Cheth", color: "Darker Blue", element: "Earth", divinatory: "Justice, Equilibrium", meaning: "Courage, inner power, control of passions", isReversed: false),
            TarotCards(name: "The Hermit", arcanum: "IX", astrological: "Aquarius", hebrew: "Teth", color: "Lighter Blue", element: "Air", divinatory: "Wisdom, Prudence", meaning: "Introspection, guidance, spiritual illumination", isReversed: false),
            TarotCards(name: "Wheel of Fortune", arcanum: "X", astrological: "Uranus", hebrew: "Jod", color: "Dazzling White", element: "Fire/Air", divinatory: "Change of Fortune", meaning: "Cycles, karma, destiny, opportunity", isReversed: false),
            TarotCards(name: "Justice", arcanum: "XI", astrological: "Neptune", hebrew: "Caph", color: "Iridescence", element: "Water", divinatory: "Force, Spiritual Power", meaning: "Balance, fairness, truth, accountability", isReversed: false),
            TarotCards(name: "The Hanged Man", arcanum: "XII", astrological: "Pisces", hebrew: "Lamed", color: "Darker Purple", element: "Water", divinatory: "Sacrifice, Expiation", meaning: "Surrender, letting go, new perspective", isReversed: false),
            TarotCards(name: "Death", arcanum: "XIII", astrological: "Aries", hebrew: "Mem", color: "Lighter Red", element: "Fire", divinatory: "Transformation, Death", meaning: "Transformation, transition, release", isReversed: false),
            TarotCards(name: "Temperance", arcanum: "XIV", astrological: "Taurus", hebrew: "Nun", color: "Darker Yellow", element: "Earth", divinatory: "Regeneration, Temperance", meaning: "Balance, moderation, harmony, healing", isReversed: false),
            TarotCards(name: "The Devil", arcanum: "XV", astrological: "Saturn", hebrew: "Samek", color: "Blue", element: "Earth", divinatory: "Fatality, Black Magic", meaning: "Materialism, bondage, fear, ignorance", isReversed: false),
            TarotCards(name: "The Tower", arcanum: "XVI", astrological: "Mars", hebrew: "Ayin", color: "Red", element: "Fire", divinatory: "Accident, Catastrophe", meaning: "Sudden change, revelation, awakening", isReversed: false),
            TarotCards(name: "The Star", arcanum: "XVII", astrological: "Gemini", hebrew: "Pe", color: "Lighter Violet", element: "Air", divinatory: "Truth, Faith, Hope", meaning: "Hope, inspiration, spiritual guidance", isReversed: false),
            TarotCards(name: "The Moon", arcanum: "XVIII", astrological: "Cancer", hebrew: "Tzaddi", color: "Lighter Green", element: "Water", divinatory: "Deception, False Friends", meaning: "Illusion, subconscious, intuition", isReversed: false),
            TarotCards(name: "The Sun", arcanum: "XIX", astrological: "Leo", hebrew: "Qoph", color: "Lighter Orange", element: "Fire", divinatory: "Happiness, Joy", meaning: "Success, joy, vitality, enlightenment", isReversed: false),
            TarotCards(name: "Judgment", arcanum: "XX", astrological: "Moon", hebrew: "Resh", color: "Green", element: "Water", divinatory: "Awakening, Resurrection", meaning: "Renewal, rebirth, inner calling", isReversed: false),
            TarotCards(name: "The World", arcanum: "XXI", astrological: "Sun", hebrew: "Shin", color: "Orange", element: "Fire", divinatory: "Success, Attainment", meaning: "Completion, achievement, integration", isReversed: false),
            TarotCards(name: "The Fool", arcanum: "XXII or 0", astrological: "Earth/Pluto", hebrew: "Tau", color: "Black/Ultra Violet", element: "Earth", divinatory: "Failure, Folly, Spirituality", meaning: "New beginnings, innocence, divine potential", isReversed: false)
        ]
    }
}
