//
//  LoginVC.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/17/25.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import CoreData

protocol LoginDelegate: AnyObject {
    func didLoginSuccessfully()
}

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    // Define the logo olive green color to match branding
    let lilaOliveGreen = UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0) // Olive green from logo

    weak var delegate: LoginDelegate?
    private let appleButton = UIButton()
    
    // Unhashed nonce for Apple Sign In
    private var currentNonce: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setGradientBackground()
        setupUI() // Setup UI first to add the button to the view hierarchy
        // Create a welcoming message at the top
        addWelcomeMessage()
        
        // Add Lila's friendly avatar
        addLilaAvatar()
        // Assign action to Apple button
        appleButton.addTarget(self, action: #selector(handleAppleSignInTapped), for: .touchUpInside)
    }

    private func setGradientBackground() {
         let gradientLayer = CAGradientLayer()
         gradientLayer.frame = view.bounds
         // Warm, friendly gradient: soft blue to deeper blue
        gradientLayer.colors = [
            UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0).cgColor, // Olive green from logo
            UIColor(red: 0.42, green: 0.48, blue: 0.23, alpha: 1.0).cgColor, // Slightly darker olive
            UIColor(red: 0.35, green: 0.4, blue: 0.18, alpha: 1.0).cgColor   // Deep olive
        ]
        
         gradientLayer.locations = [0.0, 0.6, 1.0]
         gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
         gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
         view.layer.insertSublayer(gradientLayer, at: 0)
         
         // Add subtle light particles effect
         addLightParticlesEffect()
     }
    
    private func addLightParticlesEffect() {
        // Create a particle emitter for light particles
        let particleEmitter = CAEmitterLayer()
        particleEmitter.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        particleEmitter.emitterShape = .circle
        particleEmitter.emitterSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        
        // Create light particle
        let cell = CAEmitterCell()
        cell.birthRate = 1.5
        cell.lifetime = 15.0
        cell.velocity = 8
        cell.velocityRange = 4
        cell.emissionRange = .pi * 2
        cell.spinRange = 0.3
        cell.scale = 0.1
        cell.scaleRange = 0.05
        cell.color = UIColor.white.withAlphaComponent(0.4).cgColor
        cell.alphaSpeed = -0.015
        
        // Create gentle glow content
        let size = 10
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

    private func moveGentlyWithFade(_ symbolLabel: UILabel, size: CGFloat) {
        // Gentle movement for friendly feeling
        let shouldFade = Bool.random()
        let movementDuration = TimeInterval.random(in: 6.0...10.0)
        let randomXOffset = CGFloat.random(in: -80...80)
        let randomYOffset = CGFloat.random(in: -80...80)
        let randomRotation = CGFloat.random(in: -0.2...0.2)
        let randomScale = CGFloat.random(in: 0.9...1.2)

        // Animation for movement, fading if chosen
        UIView.animate(withDuration: movementDuration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            symbolLabel.center = CGPoint(
                x: symbolLabel.center.x + randomXOffset,
                y: symbolLabel.center.y + randomYOffset
            )
            symbolLabel.transform = CGAffineTransform(rotationAngle: randomRotation).scaledBy(x: randomScale, y: randomScale)
            symbolLabel.alpha = shouldFade ? 0.3 : CGFloat.random(in: 0.6...1.0)
        }) { [weak self] _ in
            if shouldFade {
                // Reposition gently
                let screenWidth = self?.view?.frame.width ?? UIScreen.main.bounds.width
                let screenHeight = self?.view?.frame.height ?? UIScreen.main.bounds.height
                
                let newX = CGFloat.random(in: 0...screenWidth)
                let newY = CGFloat.random(in: 0...screenHeight)
                symbolLabel.center = CGPoint(x: newX, y: newY)
                symbolLabel.alpha = 0.2
                
                // Gentle fade-in
                UIView.animate(withDuration: 3.0, delay: 0, options: [.curveEaseOut], animations: {
                    symbolLabel.alpha = CGFloat.random(in: 0.6...1.0)
                })
            }
            // Continue the gentle animation
            self?.moveGentlyWithFade(symbolLabel, size: size)
        }
    }
    private func addWelcomeMessage() {
        let welcomeContainer = UIStackView()
        welcomeContainer.axis = .horizontal
        welcomeContainer.alignment = .center
        welcomeContainer.spacing = 8
        welcomeContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeContainer)
        

        
        // Lila Logo ImageView
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "asklilapng") // Ensure "lilalogo.png" is in Assets.xcassets
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Add elements to the stack
    
        welcomeContainer.addArrangedSubview(logoImageView)

        NSLayoutConstraint.activate([
            welcomeContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.5),
            
            logoImageView.widthAnchor.constraint(equalToConstant: 190), // Adjust size as needed
            logoImageView.heightAnchor.constraint(equalToConstant: 120)  // Adjust size as needed
        ])

        // Fade-in animation
        welcomeContainer.alpha = 0
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.curveEaseInOut], animations: {
            welcomeContainer.alpha = 1.0
        })

        // Tagline Label
        let taglineLabel = UILabel()
        taglineLabel.text = ""
        taglineLabel.font = UIFont(name: "Avenir-Light", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .light)
        taglineLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        taglineLabel.textAlignment = .center
        taglineLabel.alpha = 0
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(taglineLabel)

        NSLayoutConstraint.activate([
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            taglineLabel.topAnchor.constraint(equalTo: welcomeContainer.bottomAnchor, constant: 8),
            taglineLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])

        UIView.animate(withDuration: 1.5, delay: 1.0, options: [.curveEaseInOut], animations: {
            taglineLabel.alpha = 1.0
        })
    }

    private func gentlePulseAnimation(_ view: UIView) {
        UIView.animate(withDuration: 3.0, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            view.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        })
    }
    
    private func addLilaAvatar() {
        // Create a circular avatar container
        let avatarSize: CGFloat = 100
        let avatarContainer = UIView()
        avatarContainer.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.2) // Light blue
        avatarContainer.layer.cornerRadius = avatarSize / 2
        avatarContainer.layer.borderWidth = 2
        avatarContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add a gentle glow effect
        avatarContainer.layer.shadowColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0).cgColor
        avatarContainer.layer.shadowOffset = CGSize.zero
        avatarContainer.layer.shadowRadius = 12
        avatarContainer.layer.shadowOpacity = 0.5
        
        // Create a friendly avatar image
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Use a smiling emoji as placeholder (would be replaced with actual avatar image)
        let label = UILabel()
        label.text = "💁🏽‍♀️"
        label.font = UIFont.systemFont(ofSize: 60)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarContainer.addSubview(label)
        view.addSubview(avatarContainer)
        
        NSLayoutConstraint.activate([
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.bottomAnchor.constraint(equalTo: appleButton.topAnchor, constant: -40),
            avatarContainer.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarContainer.heightAnchor.constraint(equalToConstant: avatarSize),
            
            label.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor)
        ])
        
        // Add subtle breathing animation
        breathingAnimation(avatarContainer)
        
        // Add friendly message bubble
        addFriendlyBubble(near: avatarContainer)
    }
    
    private func breathingAnimation(_ view: UIView) {
        // Create a breathing effect - gentle expanding and contracting
        UIView.animate(withDuration: 4.0, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            view.layer.shadowOpacity = 0.7
        }) { _ in
            UIView.animate(withDuration: 4.0, animations: {
                view.transform = CGAffineTransform.identity
                view.layer.shadowOpacity = 0.5
            })
        }
    }
    
    private func addFriendlyBubble(near avatarView: UIView) {
        // Create speech bubble container
        let bubbleContainer = UIView()
        bubbleContainer.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        bubbleContainer.layer.cornerRadius = 15
        bubbleContainer.alpha = 0
        bubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add friendly greeting text
        let greetingLabel = UILabel()
        greetingLabel.text = "Hi there! I'm Lila."
        greetingLabel.font = UIFont(name: "Avenir-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
        greetingLabel.textColor = UIColor.white
        greetingLabel.textAlignment = .center
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleContainer.addSubview(greetingLabel)
        view.addSubview(bubbleContainer)
        
        NSLayoutConstraint.activate([
            bubbleContainer.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 15),
            bubbleContainer.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor, constant: -10),
            bubbleContainer.widthAnchor.constraint(equalToConstant: 150),
            bubbleContainer.heightAnchor.constraint(equalToConstant: 40),
            
            greetingLabel.centerXAnchor.constraint(equalTo: bubbleContainer.centerXAnchor),
            greetingLabel.centerYAnchor.constraint(equalTo: bubbleContainer.centerYAnchor)
        ])
        
        // Animate the speech bubble
        UIView.animate(withDuration: 1.0, delay: 1.5, options: [.curveEaseOut], animations: {
            bubbleContainer.alpha = 1.0
        }) { _ in
            // Fade out after a few seconds
            UIView.animate(withDuration: 1.0, delay: 4.0, options: [.curveEaseIn], animations: {
                bubbleContainer.alpha = 0
            }) { _ in
                // Show a second message
                greetingLabel.text = "Let's chat!"
                
                // Show the bubble again after a brief pause
                UIView.animate(withDuration: 1.0, delay: 0.5, options: [.curveEaseOut], animations: {
                    bubbleContainer.alpha = 1.0
                }) { _ in
                    // Fade out after a few seconds
                    UIView.animate(withDuration: 1.0, delay: 3.0, options: [.curveEaseIn], animations: {
                        bubbleContainer.alpha = 0
                    })
                }
            }
        }
    }

    private func configureButton(_ button: UIButton, title: String, systemImageName: String? = nil, imageName: String? = nil) {
        // Button styling - more mystical/spiritual look
        button.layer.cornerRadius = 25 // More rounded
        button.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.8) // Dark purple-blue
        
        // Enhance shadow for ethereal glow
        button.layer.shadowColor = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0).cgColor // Purple glow
        button.layer.shadowOpacity = 0.6
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        
        // Subtle border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        // Set button text
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Medium", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .medium)

        // Configure Image
        var logoImage: UIImage?
        
        if let systemImageName = systemImageName {
            logoImage = UIImage(systemName: systemImageName)
        } else if let imageName = imageName {
            logoImage = UIImage(named: imageName)
        }
        
        if let logoImage = logoImage {
            button.setImage(logoImage.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
        }

        // Adjust image and text insets
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

        // Add subtle hover effect
        button.addTarget(self, action: #selector(buttonHighlight), for: .touchDown)
        button.addTarget(self, action: #selector(buttonNormal), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonNormal), for: .touchUpOutside)
    }

    private func setupUI() {
        configureButton(appleButton, title: "Continue with Apple", imageName: "applelogo")
        
        view.addSubview(appleButton)

        setupConstraints()

        appleButton.addTarget(self, action: #selector(handleAppleSignInTapped), for: .touchUpInside)
    }

     @objc private func buttonHighlight(_ sender: UIButton) {
         UIView.animate(withDuration: 0.2) {
             sender.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.9)
             sender.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
             sender.layer.shadowOpacity = 0.8
         }
     }
     
     @objc private func buttonNormal(_ sender: UIButton) {
         UIView.animate(withDuration: 0.2) {
             sender.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.8)
             sender.transform = .identity
             sender.layer.shadowOpacity = 0.6
         }
     }
  
    private func setupConstraints() {
        appleButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Apple button positioned centrally
            appleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            appleButton.widthAnchor.constraint(equalToConstant: 280),
            appleButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func handleAppleSignInTapped() {
        print("Apple Sign-In button tapped.")
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // Add this required method from the presentation context provider protocol
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    // MARK: - Nonce Generation for Apple Sign In
    
    // Adapted from Apple documentation
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            for random in randoms {
                if remainingLength == 0 {
                    break
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    // Hashes a string using SHA256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    private func navigateToHome() {
        let welcomeVC = WelcomeViewController()
        let navController = UINavigationController(rootViewController: welcomeVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }

    private func saveUserInfoToCoreData(userId: String, displayName: String?, email: String?) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("⚠️ Could not access AppDelegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Check if user already exists
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let existingUsers = try context.fetch(fetchRequest)
            
            if let existingUser = existingUsers.first {
                // Update existing user
                existingUser.displayName = displayName
                existingUser.email = email
                existingUser.lastLoginDate = Date()
            } else {
                // Create a new user
                let user = UserEntity(context: context)
                user.userId = userId
                user.displayName = displayName
                user.email = email
                user.lastLoginDate = Date()
            }
            
            // Save to Core Data
            try context.save()
            print("✅ User data saved successfully to CoreData")
            
            // Save userId to UserDefaults for login state
            UserDefaults.standard.set(userId, forKey: "currentUserId")
        } catch {
            print("❌ Error saving user data to CoreData: \(error.localizedDescription)")
        }
    }

    // MARK: - Apple Sign-In
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("Error: Identity token is missing or invalid")
                return
            }
            
            // Generate a unique user ID for the user
            let userId = appleIDCredential.user
            
            // Get user info
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            let givenName = fullName?.givenName ?? "User"
            
            // Save user data to CoreData
            saveUserInfoToCoreData(userId: userId, displayName: givenName, email: email)
            
            // Save AppleID user token to keychain for later use if needed
            // This is a simplification - in a real app, you'd want to properly secure this
            let keychainKey = "appleIdentityToken"
            if let data = tokenString.data(using: .utf8) {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: keychainKey,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
                ]
                
                // Delete any existing keychain item
                SecItemDelete(query as CFDictionary)
                
                // Add the new keychain item
                let status = SecItemAdd(query as CFDictionary, nil)
                print("Keychain save status: \(status)")
            }
            
            // Navigate to main app screen
            DispatchQueue.main.async {
                self.navigateToHome()
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed with error: \(error.localizedDescription)")
    }
}
