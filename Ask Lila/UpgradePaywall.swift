import UIKit
import StoreKit

class UpgradeToPremiumViewController: UIViewController {

    private let oliveGreen = UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0)
    private var premiumProduct: Product?

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupHeader()
        setupAvatar()
        setupBenefits()
        loadPremiumProduct()
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
        title.text = "You're Using Lila to the Fullest ✨"
        title.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        title.textAlignment = .center
        contentView.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = "Upgrade to Premium to continue your journey without limits."
        subtitle.font = UIFont.systemFont(ofSize: 16)
        subtitle.textColor = .gray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        contentView.addArrangedSubview(subtitle)
    }

    private func setupAvatar() {
        let avatar = UILabel()
        avatar.text = "💁🏽‍♀️"
        avatar.font = .systemFont(ofSize: 60)
        avatar.textAlignment = .center
        contentView.addArrangedSubview(avatar)
    }

    private func setupBenefits() {
        let features = UIStackView()
        features.axis = .vertical
        features.spacing = 12

        features.addArrangedSubview(makeFeatureRow(icon: "infinity", text: "Unlimited Ask Lila messages"))
        features.addArrangedSubview(makeFeatureRow(icon: "heart.text.square", text: "Full access to Relationship Insights"))
        features.addArrangedSubview(makeFeatureRow(icon: "book", text: "South Node Story Decoder"))
        features.addArrangedSubview(makeFeatureRow(icon: "wand.and.stars", text: "Early access to new features"))

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
        label.numberOfLines = 0

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        return stack
    }

    private func loadPremiumProduct() {
        Task {
            do {
                let ids: Set<String> = ["asklila.premiumAccess"]
                let products = try await Product.products(for: ids)
                if let product = products.first {
                    self.premiumProduct = product
                    self.contentView.addArrangedSubview(self.makeProductButton(for: product))
                }
            } catch {
                print("❌ Failed to load Premium product: \(error)")
            }
        }
    }

    private func makeProductButton(for product: Product) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle("Upgrade to Premium – \(product.displayPrice)", for: .normal)
        button.backgroundColor = oliveGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addAction(UIAction(handler: { [weak self] _ in
            Task { await self?.purchase(product) }
        }), for: .touchUpInside)
        return button
    }

    private func setupDismissButton() {
        let dismiss = UIButton(type: .system)
        dismiss.setTitle("Not Now", for: .normal)
        dismiss.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        contentView.addArrangedSubview(dismiss)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    private func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()

                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    await appDelegate.updateSubscriptionLevel()
                    print("🛒 Premium purchased: \(AccessManager.shared.currentLevel)")
                }

                dismiss(animated: true)

            case .userCancelled:
                print("User cancelled Premium purchase")
            default:
                print("Unhandled purchase result")
            }
        } catch {
            print("❌ Premium purchase failed: \(error)")
        }
    }
}
