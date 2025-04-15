//
//  AICostDashboardViewController.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/14/25.
//


// AICostDashboardViewController.swift
// AskLila Admin Dashboard for AI Usage and Cost

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AICostDashboardViewController: UIViewController {

    private var costEntries: [AICostEntry] = []
    private let tableView = UITableView()
    private let totalLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Cost Dashboard"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupTotalLabel()
        fetchCostData()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CostCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }

    private func setupTotalLabel() {
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        totalLabel.textAlignment = .center
        totalLabel.font = UIFont.boldSystemFont(ofSize: 18)
        view.addSubview(totalLabel)
        NSLayoutConstraint.activate([
            totalLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            totalLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            totalLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            totalLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func fetchCostData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("aiCosts")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching AI costs: \(error.localizedDescription)")
                    return
                }

                self.costEntries = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let model = data["model"] as? String,
                        let inputTokens = data["inputTokens"] as? Int,
                        let outputTokens = data["outputTokens"] as? Int,
                        let totalTokens = data["totalTokens"] as? Int,
                        let costUSD = data["costUSD"] as? Double,
                        let readingType = data["readingType"] as? String,
                        let chartName = data["chartName"] as? String,
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                    else { return nil }

                    return AICostEntry(
                        model: model,
                        inputTokens: inputTokens,
                        outputTokens: outputTokens,
                        totalTokens: totalTokens,
                        costUSD: costUSD,
                        readingType: readingType,
                        chartName: chartName,
                        timestamp: timestamp
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.updateTotalLabel()
                    self.tableView.reloadData()
                }
            }
    }

    private func updateTotalLabel() {
        let totalCost = costEntries.reduce(0) { $0 + $1.costUSD }
        totalLabel.text = String(format: "Total Spend: $%.2f", totalCost)
    }
}

extension AICostDashboardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return costEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = costEntries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CostCell", for: indexPath)
        let date = DateFormatter.localizedString(from: entry.timestamp, dateStyle: .short, timeStyle: .short)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(date)\n\(entry.model) – $\(String(format: "%.4f", entry.costUSD)) | \(entry.readingType)"
        return cell
    }
}
