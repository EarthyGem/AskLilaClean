//
//  Splash.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/10/25.
//

import Foundation
import UIKit

class SplashViewController: UIViewController {

    let logoImageView = UIImageView()
    let missionLabel = UILabel()
    let subtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupLogo()
        setupLabels()
        animateEntrance()
    }

    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 1.0).cgColor, // Olive green
            UIColor(red: 0.42, green: 0.48, blue: 0.23, alpha: 1.0).cgColor,
            UIColor(red: 0.35, green: 0.4, blue: 0.18, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLogo() {
        logoImageView.image = UIImage(named: "asklilapng")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func setupLabels() {
        missionLabel.text = "Living a Divine Life"
        missionLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
        missionLabel.textColor = .white
        missionLabel.textAlignment = .center
        missionLabel.alpha = 0
        missionLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "A journey guided by the stars within you"
        subtitleLabel.font = UIFont(name: "Avenir-Light", size: 16)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(missionLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            missionLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 10),
            missionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: missionLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func animateEntrance() {
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.curveEaseOut], animations: {
            self.logoImageView.alpha = 1.0
        })

        UIView.animate(withDuration: 1.5, delay: 1.2, options: [.curveEaseOut], animations: {
            self.missionLabel.alpha = 1.0
            self.subtitleLabel.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.transitionToNextScreen()
            }
        }
    }

    private func transitionToNextScreen() {
        let loginVC = LoginViewController()
        loginVC.modalTransitionStyle = .crossDissolve
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true, completion: nil)
    }
}
