

import UIKit
import StoreKit

class PaywallViewController: UIViewController {

    private let lilaOliveGreen = UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0)
    private var products: [Product] = []
    private let featureDescriptions = [
        "asklila.fullAccess": "Unlimited Ask Lila questions and self-insight guidance.",
        "asklila.premiumAccess": "Everything in Full Access + South Node stories and Relationship analysis."
    ]

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupHeader()
        setupAvatar()
        setupFeatures()
        loadProducts()
        setupRestoreButton()
        setupDismissButton()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        contentView.axis = .vertical
        contentView.spacing = 24
        contentView.alignment = .fill
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func setupHeader() {
        let title = UILabel()
        title.text = "Upgrade for Divine Access"
        title.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        title.textAlignment = .center
        contentView.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = "Choose your plan below"
        subtitle.font = UIFont.systemFont(ofSize: 16)
        subtitle.textAlignment = .center
        subtitle.textColor = .gray
        contentView.addArrangedSubview(subtitle)
    }

    private func setupAvatar() {
        let avatar = UILabel()
        avatar.text = "💁🏽‍♀️"
        avatar.font = .systemFont(ofSize: 60)
        avatar.textAlignment = .center
        contentView.addArrangedSubview(avatar)
    }

    private func setupFeatures() {
        let features = UIStackView()
        features.axis = .vertical
        features.spacing = 12

        features.addArrangedSubview(makeFeatureRow(icon: "sparkles", text: "Unlimited Ask Lila questions"))
        features.addArrangedSubview(makeFeatureRow(icon: "person.crop.circle", text: "Personalized guidance"))
        features.addArrangedSubview(makeFeatureRow(icon: "book", text: "South Node Storyteller"))
        features.addArrangedSubview(makeFeatureRow(icon: "heart", text: "Relationship Insights"))

        contentView.addArrangedSubview(features)
    }

    private func makeFeatureRow(icon: String, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemGreen
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16)

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        return stack
    }

    private func loadProducts() {
        Task {
            do {
                let ids: Set<String> = ["asklila.fullAccess", "asklila.premiumAccess"]
                products = try await Product.products(for: ids)
                for product in products.sorted(by: { $0.displayName < $1.displayName }) {
                    contentView.addArrangedSubview(makeProductCard(for: product))
                }
            } catch {
                print("❌ Failed to load products: \(error)")
            }
        }
    }

    private func makeProductCard(for product: Product) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray4.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.1
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = product.displayName
        title.font = UIFont.boldSystemFont(ofSize: 18)

        let desc = UILabel()
        desc.text = featureDescriptions[product.id] ?? ""
        desc.font = UIFont.systemFont(ofSize: 14)
        desc.textColor = .gray
        desc.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Subscribe \(product.displayPrice)", for: .normal)
        button.backgroundColor = lilaOliveGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addAction(UIAction(handler: { [weak self] _ in
            Task { await self?.purchase(product) }
        }), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, button])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])

        return card
    }

    private func setupRestoreButton() {
        let restore = UIButton(type: .system)
        restore.setTitle("Restore Purchases", for: .normal)
        restore.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        contentView.addArrangedSubview(restore)
    }

    private func setupDismissButton() {
        let close = UIButton(type: .system)
        close.setTitle("Dismiss", for: .normal)
        close.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        contentView.addArrangedSubview(close)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    @objc private func restoreTapped() {
        Task {
            do {
                try await AppStore.sync()
                await (UIApplication.shared.delegate as? AppDelegate)?.updateSubscriptionLevel()
                dismiss(animated: true)
            } catch {
                print("Restore failed: \(error)")
            }
        }
    }

    private func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                await (UIApplication.shared.delegate as? AppDelegate)?.updateSubscriptionLevel()
                dismiss(animated: true)
            case .userCancelled:
                print("Cancelled")
            default:
                print("Other outcome")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}
