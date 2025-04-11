import UIKit
import QuartzCore

class WelcomeViewController: UIViewController {

    // MARK: - Properties
    private var gradientLayer: CAGradientLayer!
    private var particleEmitter: CAEmitterLayer!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupLightParticlesEffect()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update frame for rotation and different screen sizes
        gradientLayer.frame = view.bounds
        particleEmitter.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        particleEmitter.emitterSize = CGSize(width: view.bounds.width, height: view.bounds.height)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update UI for iPad/iPhone or orientation changes
        updateUIForCurrentDevice()
    }

    // MARK: - UI Setup
    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.42, green: 0.48, blue: 0.23, alpha: 1.0).cgColor,
            UIColor(red: 0.35, green: 0.4, blue: 0.18, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLightParticlesEffect() {
        particleEmitter = CAEmitterLayer()
        particleEmitter.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        particleEmitter.emitterShape = .circle
        particleEmitter.emitterSize = CGSize(width: view.bounds.width, height: view.bounds.height)

        let cell = CAEmitterCell()
        cell.birthRate = 1.2
        cell.lifetime = 14.0
        cell.velocity = 8
        cell.velocityRange = 4
        cell.emissionRange = .pi * 2
        cell.spinRange = 0.3
        cell.scale = 0.1
        cell.scaleRange = 0.05
        cell.color = UIColor.white.withAlphaComponent(0.3).cgColor
        cell.alphaSpeed = -0.01

        let size = UIDevice.current.userInterfaceIdiom == .pad ? 15 : 10 // Larger particles for iPad
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        let glowImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        cell.contents = glowImage?.cgImage
        particleEmitter.emitterCells = [cell]
        view.layer.insertSublayer(particleEmitter, at: 1)
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24 // Increased spacing for better readability
        stack.translatesAutoresizingMaskIntoConstraints = false

        // App Logo/Image (Optional)
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "app_logo") // Add your logo image
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        logoImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        // Uncomment to use the logo
        // stack.addArrangedSubview(logoImageView)
        // stack.setCustomSpacing(30, after: logoImageView)

        // Title Label
        let titleLabel = createLabel(
            text: "Welcome to Ask Lila",
            font: UIFont(name: "Avenir-Heavy", size: adaptiveFontSize(for: 32)),
            color: .white,
            alpha: 1.0
        )

        // Mission Statement
        let missionLabel = createLabel(
            text: "Ask Lila was created to help you live more in sync with your inner rhythm.\n\nWhen you understand your patterns, you can make more meaningful choices—and live a more connected, intentional life.",
            font: UIFont(name: "Avenir-Light", size: adaptiveFontSize(for: 18)),
            color: .white,
            alpha: 0.95
        )

        // Info Label
        let infoLabel = createLabel(
            text: "Lila isn't here to predict your future. She's here to help you see the deeper logic behind what's already unfolding.",
            font: UIFont(name: "Avenir-Medium", size: adaptiveFontSize(for: 16)),
            color: .white,
            alpha: 0.85
        )

        // Privacy Label
        let privacyLabel = createLabel(
            text: "Your data stays private. It's never shared or sold.",
            font: UIFont(name: "Avenir-LightOblique", size: adaptiveFontSize(for: 14)),
            color: .white,
            alpha: 0.7
        )

        // Continue Button
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("Begin Your Journey", for: .normal)
        continueButton.setTitleColor(UIColor.white, for: .normal)
        continueButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: adaptiveFontSize(for: 18))
        continueButton.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.3)
        continueButton.layer.cornerRadius = 16
        continueButton.layer.shadowColor = UIColor.white.cgColor
        continueButton.layer.shadowOpacity = 0.5
        continueButton.layer.shadowOffset = .zero
        continueButton.layer.shadowRadius = 12
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        // Add subtle pulse animation to button
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.7
        pulseAnimation.duration = 1.8
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        continueButton.layer.add(pulseAnimation, forKey: "pulseAnimation")
        // Add elements to stack
        [titleLabel, missionLabel, infoLabel, privacyLabel, continueButton].forEach {
            stack.addArrangedSubview($0)
        }

        // Add stack to view
        view.addSubview(stack)

        // Setup constraints - adaptive for different devices
        NSLayoutConstraint.activate([
            continueButton.widthAnchor.constraint(equalToConstant: UIDevice.current.userInterfaceIdiom == .pad ? 320 : 280),
            continueButton.heightAnchor.constraint(equalToConstant: UIDevice.current.userInterfaceIdiom == .pad ? 60 : 50),

            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: UIDevice.current.userInterfaceIdiom == .pad ? 60 : 30),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: UIDevice.current.userInterfaceIdiom == .pad ? -60 : -30),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20)
        ])

        // Initial update for current device
        updateUIForCurrentDevice()
    }

    // MARK: - Helper Methods
    private func createLabel(text: String, font: UIFont?, color: UIColor, alpha: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color.withAlphaComponent(alpha)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }

    private func adaptiveFontSize(for size: CGFloat) -> CGFloat {
        // Return larger font for iPad
        return UIDevice.current.userInterfaceIdiom == .pad ? size * 1.3 : size
    }

    private func updateUIForCurrentDevice() {
        // Adjust UI elements based on device type and orientation
        let isLandscape = UIDevice.current.orientation.isLandscape
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        // Adjust particle effect intensity
        if let cell = particleEmitter.emitterCells?.first {
            cell.birthRate = isPad ? (isLandscape ? 2.0 : 1.6) : (isLandscape ? 1.4 : 1.2)
            cell.scale = isPad ? 0.15 : 0.1
        }
    }

    // MARK: - Actions
    @objc private func continueTapped() {
        // Apply a nice tap animation
        UIView.animate(withDuration: 0.15, animations: {
            if let button = self.view.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.last as? UIButton {
                button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                if let button = self.view.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.last as? UIButton {
                    button.transform = .identity
                }
            }

            // Navigate to the next screen
            let profileVC = MyUserProfileViewController()
            self.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
}
