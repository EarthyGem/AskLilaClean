import UIKit

class WishSpreadViewController: UIViewController, UIScrollViewDelegate {
    private let questionField = UITextField()
    private let askButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let serviceSelector = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
    private let deckTypeSelector = UISegmentedControl(items: ["Church of Light", "Rider-Waite"])

    private var cardViews = [UIImageView]()
    private var currentDeckType: TarotDeckType = .churchOfLight
    private var dealtCards: [ChurchOfLightTarotCard] = []

    private let scrollView = UIScrollView()
    private let spreadContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Wish Spread"

        for _ in 0..<15 {
            let cardView = UIImageView()
            cardView.image = UIImage(named: "col_cardBack")
            cardView.contentMode = .scaleAspectFit
            cardView.layer.cornerRadius = 8
            cardView.clipsToBounds = true
            cardViews.append(cardView)
        }

        setupUI()
        layoutWishCards(in: spreadContainer)
    }

    private func setupUI() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        spreadContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(spreadContainer)
        view.addSubview(scrollView)

        serviceSelector.selectedSegmentIndex = 0
        deckTypeSelector.selectedSegmentIndex = 0
        serviceSelector.translatesAutoresizingMaskIntoConstraints = false
        deckTypeSelector.translatesAutoresizingMaskIntoConstraints = false
        questionField.placeholder = "Enter your question for the Wish Spread"
        questionField.borderStyle = .roundedRect
        askButton.setTitle("Ask the Cards", for: .normal)
        questionField.translatesAutoresizingMaskIntoConstraints = false
        askButton.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        askButton.addTarget(self, action: #selector(handleAsk), for: .touchUpInside)

        [serviceSelector, deckTypeSelector, questionField, askButton, resultLabel].forEach {
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            serviceSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            serviceSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            deckTypeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            deckTypeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deckTypeSelector.leadingAnchor.constraint(equalTo: serviceSelector.trailingAnchor, constant: 10),

            questionField.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 10),
            questionField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            askButton.topAnchor.constraint(equalTo: questionField.bottomAnchor, constant: 10),
            askButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: askButton.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spreadContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            spreadContainer.heightAnchor.constraint(equalToConstant: 500)
        ])
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return spreadContainer
    }

    private func layoutWishCards(in container: UIView) {
        let cardWidth: CGFloat = 30
        let cardHeight: CGFloat = 50
        let spacing: CGFloat = 8

        let centerX = UIScreen.main.bounds.width / 2
        let startY: CGFloat = 30

        func placeCard(_ i: Int, x: CGFloat, y: CGFloat) {
            let card = cardViews[i]
            card.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: cardWidth),
                card.heightAnchor.constraint(equalToConstant: cardHeight),
                card.centerXAnchor.constraint(equalTo: container.leadingAnchor, constant: x),
                card.topAnchor.constraint(equalTo: container.topAnchor, constant: y)
            ])
        }

        // 4–5–6 (wish intention, top)
        for i in 3...5 {
            let offset = CGFloat(i - 4)
            placeCard(i, x: centerX + offset * (cardWidth + spacing), y: startY)
        }

        // 13–14–15 (what will be realized) — drop lower
        let middleY = startY + cardHeight + 70
        for i in 12...14 {
            let offset = CGFloat(i - 13)
            placeCard(i, x: centerX + offset * (cardWidth + spacing), y: middleY)
        }

        // Wish card (W) — overlapping 4–5–6 and above 13–14–15
        let wishCard = UIImageView()
        wishCard.image = UIImage(named: "wish_card") ?? UIImage(named: "col_cardBack")
        wishCard.contentMode = .scaleAspectFit
        wishCard.layer.cornerRadius = 8
        wishCard.clipsToBounds = true
        container.addSubview(wishCard)
        wishCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wishCard.widthAnchor.constraint(equalToConstant: cardWidth),
            wishCard.heightAnchor.constraint(equalToConstant: cardHeight),
            wishCard.centerXAnchor.constraint(equalTo: container.leadingAnchor, constant: centerX),
            wishCard.bottomAnchor.constraint(equalTo: cardViews[13].topAnchor, constant: 10) // slight overlap
        ])

        // 1–2–3 (surrounding you) — to the left, higher and spaced away from center
        let sideY = middleY - cardHeight * 0.4
        let leftGroupOffset: CGFloat = 4.4
        for i in 0...2 {
            let offset = CGFloat(2 - i)
            placeCard(i, x: centerX - (cardWidth + spacing) * leftGroupOffset + offset * (cardWidth + spacing), y: sideY)
        }
        // 7–8–9 (opposition) — to the right
        for i in 6...8 {
            let offset = CGFloat(i - 7)
            placeCard(i, x: centerX + (cardWidth + spacing) * 3.4 + offset * (cardWidth + spacing), y: sideY)
        }

        // 10–11–12 (comes to your home) — below center
        let bottomY = middleY + cardHeight + 40
        for i in 9...11 {
            let offset = CGFloat(i - 10)
            placeCard(i, x: centerX + offset * (cardWidth + spacing), y: bottomY)
        }
    }


    @objc private func handleAsk() {
        print("🔮 Ask button tapped – coming soon!")
    }
}

class WishPromptBuilder {
    func buildPrompt(question: String, cardNames: [String], deckType: TarotDeckType) -> String {
        var prompt = """
        # WISH SPREAD TAROT READING

        ## Question
        "\(question)"

        ## Spread
        The Wish Spread (15 cards + 1 optional significator)

        ## Interpretation Instructions:

        - **Cards 1–2–3** (Left): "This is what surrounds you."
        - **Cards 4–5–6** (Top): "This is your wish."
        - **Cards 7–8–9** (Right): "This is what opposes you."
        - **Cards 10–11–12** (Bottom): "This is what comes to your home."
        - **Cards 13–14–15** (Center): "This is what you will realize."

        ## Cards:
        """

        for (i, name) in cardNames.enumerated() {
            prompt += "\n- Card \(i + 1): \(name)"
        }

        prompt += """

        ## Special Rule:

        - If the **Nine of Cups** appears *outside cards 7–9*, the wish may be fulfilled.
        - If it appears in cards 7–9, the wish may be denied. The cards will show why.
        - If it is absent, interpret based on the general tone (positive = likely fulfilled, negative = not).

        ## Guidance:

        Read the spread with elegance and insight. Weave a narrative showing the querent's emotional journey, inner dynamics, and ultimate realization. Close with a reflection on the nature of their wish and the energies that support or challenge its manifestation.
        """

        return prompt
    }
}
