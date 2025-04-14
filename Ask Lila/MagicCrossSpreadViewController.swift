//  MagicCrossSpreadViewController.swift
//  Ask Lila

import UIKit

class MagicCrossSpreadViewController: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let serviceSelector = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
    private let deckTypeSelector = UISegmentedControl(items: ["Church of Light", "Rider-Waite"])
    private var cardViews = [UIImageView]()

    private var deckManager = ChurchOfLightDeckManager()
    private var riderWaiteDeckManager = RiderWaiteDeckManager()
    private var currentDeckType: TarotDeckType = .churchOfLight
    private var question: String = ""
    private var dealtCards: [ChurchOfLightTarotCard] = []
    private var dealtRiderWaiteCards: [RiderWaiteTarotCard] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Magic Cross Spread"

        setupUI()
        setupCardViews()
        layoutMagicCrossCards()
    }

    private func setupUI() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.5
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        [serviceSelector, deckTypeSelector, questionField, askButton, resultLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        serviceSelector.selectedSegmentIndex = 0
        serviceSelector.addTarget(self, action: #selector(serviceChanged), for: .valueChanged)

        deckTypeSelector.selectedSegmentIndex = 0
        deckTypeSelector.addTarget(self, action: #selector(deckTypeChanged), for: .valueChanged)

        questionField.placeholder = "Enter your question for the Magic Cross"
        questionField.borderStyle = .roundedRect

        askButton.setTitle("Ask the Cards", for: .normal)
        askButton.addTarget(self, action: #selector(handleAsk), for: .touchUpInside)

        resultLabel.numberOfLines = 0
        resultLabel.font = UIFont.systemFont(ofSize: 16)

        NSLayoutConstraint.activate([
            serviceSelector.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            serviceSelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            deckTypeSelector.centerYAnchor.constraint(equalTo: serviceSelector.centerYAnchor),
            deckTypeSelector.leadingAnchor.constraint(equalTo: serviceSelector.trailingAnchor, constant: 10),
            deckTypeSelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            questionField.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 10),
            questionField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 10),
            askButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            resultLabel.topAnchor.constraint(greaterThanOrEqualTo: askButton.bottomAnchor, constant: 800),
            resultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupCardViews() {
        for cardView in cardViews { cardView.removeFromSuperview() }
        cardViews.removeAll()

        for _ in 0..<13 {
            let cardView = UIImageView()
            let backImageName = currentDeckType == .churchOfLight ? "col_cardBack" : "rw_cardBack"
            cardView.image = UIImage(named: backImageName)
            cardView.contentMode = .scaleAspectFit
            cardView.layer.cornerRadius = 6
            cardView.clipsToBounds = true
            cardView.translatesAutoresizingMaskIntoConstraints = false

            cardViews.append(cardView)
            contentView.addSubview(cardView)
        }
    }

    private func layoutMagicCrossCards() {
        let cardWidth: CGFloat = 50
        let cardHeight: CGFloat = 80
        let spacing: CGFloat = 8

        contentView.layoutIfNeeded()

        let centerX = contentView.bounds.midX
        let topY = askButton.frame.maxY + 40
        let centerY = topY + 3 * (cardHeight + spacing)

        // Horizontal (cards 0-4)
        for i in 0..<5 {
            let card = cardViews[i]
            let xOffset = CGFloat(i - 2) * (cardWidth + spacing)
            card.frame = CGRect(x: centerX + xOffset - cardWidth / 2,
                                y: centerY,
                                width: cardWidth,
                                height: cardHeight)
        }

        // Vertical (cards 5-12)
        let verticalOffsets: [CGFloat] = [-2, -1, 1, 2, 3, 4, 5, 6]
        for i in 0..<8 {
            let card = cardViews[i + 5]
            let yOffset = verticalOffsets[i] * (cardHeight + spacing)
            card.frame = CGRect(x: centerX - cardWidth / 2,
                                y: centerY + yOffset,
                                width: cardWidth,
                                height: cardHeight)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

    @objc private func serviceChanged() {
        switch serviceSelector.selectedSegmentIndex {
        case 0: TarotAIServiceManager.shared.currentProvider = .openAI
        case 1: TarotAIServiceManager.shared.currentProvider = .claude
        case 2: TarotAIServiceManager.shared.currentProvider = .huggingFace
        default: break
        }
    }

    @objc private func deckTypeChanged() {
        currentDeckType = deckTypeSelector.selectedSegmentIndex == 0 ? .churchOfLight : .riderWaite
        setupCardViews()
        layoutMagicCrossCards()
    }

    @objc private func handleAsk() {
        view.endEditing(true)
        question = questionField.text ?? ""
        guard !question.isEmpty else {
            resultLabel.text = "Please enter a question."
            return
        }

        let backImageName = currentDeckType == .churchOfLight ? "col_cardBack" : "rw_cardBack"
        for cardView in cardViews {
            cardView.image = UIImage(named: backImageName)
            cardView.transform = .identity
        }

        switch currentDeckType {
        case .churchOfLight:
            deckManager = ChurchOfLightDeckManager()
            deckManager.shuffleAndCut(times: 3)
            dealtCards = Array(deckManager.deck.prefix(13))
            interpretMagicCrossChurchOfLight()
        case .riderWaite:
            riderWaiteDeckManager = RiderWaiteDeckManager()
            riderWaiteDeckManager.shuffleAndCut(times: 3)
            dealtRiderWaiteCards = Array(riderWaiteDeckManager.deck.prefix(13))
            interpretMagicCrossRiderWaite()
        }

        resultLabel.text = "Reading..."
    }

    private func interpretMagicCrossChurchOfLight() {
        let promptBuilder = MagicCrossPromptBuilder()
        let cardNames = dealtCards.map { $0.name + ($0.isReversed ? " (Reversed)" : "") }
        let prompt = promptBuilder.buildPrompt(question: question, cardNames: cardNames, deckType: .churchOfLight)

        TarotAIServiceManager.shared.currentService.generateTarotReading(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let answer): self?.resultLabel.text = answer
                case .failure(let error): self?.resultLabel.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func interpretMagicCrossRiderWaite() {
        let promptBuilder = MagicCrossPromptBuilder()
        let cardNames = dealtRiderWaiteCards.map { $0.name + ($0.isReversed ? " (Reversed)" : "") }
        let prompt = promptBuilder.buildPrompt(question: question, cardNames: cardNames, deckType: .riderWaite)

        TarotAIServiceManager.shared.currentService.generateTarotReading(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let answer): self?.resultLabel.text = answer
                case .failure(let error): self?.resultLabel.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}


class MagicCrossPromptBuilder {
    func buildPrompt(question: String, cardNames: [String], deckType: TarotDeckType) -> String {
        let positions = [
            "1. Past (Left Arm)",
            "2. Past (Right Arm)",
            "3. Present (Heart of the Cross)",
            "4. Opposition (Right)",
            "5. Adversaries (Far Right)",
            "6. Hopes (Top)",
            "7. Expectations (Just above Present)",
            "8–13. Future Path (descending down the cross)"
        ]

        var prompt = """
        # MAGIC CROSS TAROT READING

        ## Question
        \"\(question)\"

        ## Spread
        Magic Cross Spread (13 cards)

        ## Cards and Positions:
        """

        for (index, name) in cardNames.enumerated() {
            prompt += "\n- Card \(index + 1): \(name)"
        }

        prompt += """

        ## Instructions for Interpretation

        - Cards 1 & 2 reflect the **Past**.
        - Card 3 is the **Present**, the heart of the cross where forces meet.
        - Cards 4 & 5 show **Opposition** and **Adversaries**.
        - Cards 6 & 7 represent **Hopes and Expectations**.
        - Cards 8 to 13 reveal the **Future Path**.

        Create a narrative that bridges the past and present with the unfolding future. Highlight Major Arcana cards as significant forces and reflect on any dominant themes. Finish with a dignified synthesis that empowers the querent.
        """

        return prompt
    }
}
