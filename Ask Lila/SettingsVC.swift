// SettingsMenuViewController.swift
// AskLila Settings and Admin Tools

import UIKit
import SwiftEphemeris
import FirebaseAuth
import FirebaseFirestore
import MessageUI

class SettingsMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {

    private let tableView = UITableView()
    private var options: [(title: String, action: Selector)] = []
    var chartCake: ChartCake!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        determineOptionsBasedOnRole()
    }

    private func determineOptionsBasedOnRole() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(currentUserId).getDocument { snapshot, error in
            let isAdmin = snapshot?.data()?["isAdmin"] as? Bool ?? false

            // Clear and build in your desired order
            self.options = [
                ("📝 Edit Birth Chart", #selector(self.openBirthChartEditor)),
                ("🗣 Language Level", #selector(self.adjustJargonLevel)),

                ("💬 Send Feedback", #selector(self.sendFeedback)),
                ("📤 Share AskLila", #selector(self.shareAskLila)),
               
            ]

            // Add admin options last
            if isAdmin {
                self.options.append(("💰 View Paywall", #selector(self.viewPaywall)))
                self.options.append(("🃏 Tarot Beta", #selector(self.openTarotBeta)))
                self.options.append(("🔄 Data Migration Dashboard", #selector(self.openMigrationDashboard)))
                self.options.append(("📊 AI Cost Dashboard", #selector(self.openCostDashboard)))
                
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }


    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    @objc private func shareAskLila() {
        let shareText = """
        I found this astrology app called AskLila that I'm really into! It's like having a personal astrologer that actually knows my chart and helps me understand myself better. No judgment, just insights. Check it out if you're curious:
        
        https://apps.apple.com/us/app/ask-lila/id6743421039
        """
    
    
    
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }

        present(activityVC, animated: true)
    }

    @objc private func sendFeedback() {
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Mail Not Configured", message: "Please set up a Mail account to send feedback.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["highsman@lilaverse.app"])
        composer.setSubject("AskLila App Feedback")
        composer.setMessageBody("Hi Lila Team,\n\nI wanted to share the following feedback:\n", isHTML: false)

        present(composer, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                                didFinishWith result: MFMailComposeResult,
                                error: Error?) {
         controller.dismiss(animated: true)
     }
    
    // MARK: - TableView Delegate/DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = options[indexPath.row].action
        perform(action)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Actions

    @objc private func openMigrationDashboard() {
        let vc = DataMigrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func openTarotBeta() {
        print("🛠️ Edit tapped — attempting to call SceneDelegate...")



        let editVC = YesNoTarotViewController()
        //    editVC.chartCake = self.chartCake
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true) {
                print("✅ Edit chart screen presented successfully")
            }
        }

    @objc private func adjustJargonLevel() {
        let alert = UIAlertController(title: "Language Preference", message: "Choose your preferred astrology language style.", preferredStyle: .actionSheet)

        let levels: [(title: String, level: JargonLevel)] = [
            ("🧘‍♀️ Plain Language", .beginner),
            ("🔮 Some Jargon", .intermediate),
            ("🧠 Astro Speak", .advanced)
        ]

        for (title, level) in levels {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                UserDefaults.standard.set(level.rawValue, forKey: "user_jargon_level")
                let confirmation = UIAlertController(title: "Updated", message: "Language level set to \(level.label)", preferredStyle: .alert)
                confirmation.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(confirmation, animated: true)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alert, animated: true)
    }


    @objc private func viewPaywall() {
        print("🛠️ Edit tapped — attempting to call SceneDelegate...")



        let editVC = PaywallViewController()
        //    editVC.chartCake = self.chartCake
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true) {
                print("✅ Edit chart screen presented successfully")
            }
        }
    @objc private func openBirthChartEditor() {
        print("🛠️ Edit tapped — attempting to call SceneDelegate...")

        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate {
            print("✅ Found SceneDelegate via windowScene")
            sceneDelegate.showEditChartScreen()
        } else {
            print("⚠️ SceneDelegate is nil or not ready")

            let editVC = EditChartViewController()
            editVC.chartCake = self.chartCake
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true) {
                print("✅ Edit chart screen presented successfully")
            }
        }
    }

    @objc private func openCostDashboard() {
        let vc = AICostDashboardViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
