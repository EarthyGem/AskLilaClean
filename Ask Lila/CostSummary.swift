//
//  CostSummary.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/14/25.
//

import Foundation
import Firebase
import FirebaseAuth

struct AICostEntry {
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let costUSD: Double
    let readingType: String
    let chartName: String
    let timestamp: Date
}

class AICostLogger {
    static let shared = AICostLogger()

    func log(_ entry: AICostEntry) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in, skipping cost logging.")
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("users")
            .document(userId)
            .collection("aiCosts")
            .document()

        let data: [String: Any] = [
            "model": entry.model,
            "inputTokens": entry.inputTokens,
            "outputTokens": entry.outputTokens,
            "totalTokens": entry.totalTokens,
            "costUSD": entry.costUSD,
            "readingType": entry.readingType,
            "chartName": entry.chartName,
            "timestamp": Timestamp(date: entry.timestamp)
        ]

        ref.setData(data) { error in
            if let error = error {
                print("❌ Error saving cost log: \(error.localizedDescription)")
            } else {
                print("✅ Cost log saved: \(entry.model), $\(String(format: "%.4f", entry.costUSD))")
            }
        }
    }
}


struct AICostManager {
    static let modelRates: [String: (input: Double, output: Double)] = [
        "gpt-4o": (input: 0.005 / 1000, output: 0.015 / 1000),
        "claude-3-sonnet": (input: 0.003 / 1000, output: 0.015 / 1000),
        "huggingface": (input: 0.002 / 1000, output: 0.002 / 1000),
        "kagi": (input: 0.004 / 1000, output: 0.004 / 1000)
    ]

    static func estimateCost(model: String, inputTokens: Int, outputTokens: Int) -> Double {
        guard let rates = modelRates[model] else {
            print("⚠️ Unknown model: \(model)")
            return 0.0
        }

        return (Double(inputTokens) * rates.input) + (Double(outputTokens) * rates.output)
    }
}
