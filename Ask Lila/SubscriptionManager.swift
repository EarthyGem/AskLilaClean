//
//  SubscriptionManager.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/18/25.
//

import StoreKit
import FirebaseAuth
import FirebaseFirestore

class SubscriptionManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = SubscriptionManager()
    private var product: SKProduct?

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func fetchSubscription() {
        let request = SKProductsRequest(productIdentifiers: ["com.lila.premium"])
        request.delegate = self
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let premiumProduct = response.products.first {
            product = premiumProduct
        }
    }

    func purchaseSubscription() {
        guard let premiumProduct = product else {
            print("❌ Subscription product not available.")
            return
        }

        let payment = SKPayment(product: premiumProduct)
        SKPaymentQueue.default().add(payment)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                grantPremiumAccess()
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    print("❌ Purchase failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }

    private func grantPremiumAccess() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userDocRef = Firestore.firestore().collection("users").document(userId)
        
        userDocRef.updateData(["isPremium": true]) { error in
            if let error = error {
                print("❌ Error updating subscription status: \(error.localizedDescription)")
            } else {
                print("✅ User is now a Premium subscriber!")
            }
        }
    }
}

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestore

class QueryManager {
    static let shared = QueryManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func canMakeQuery(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let today = getCurrentDateString()
        let userDocRef = db.collection("users").document(userId)
        
        userDocRef.getDocument { document, error in
            if let error = error {
                print("❌ Error checking query count: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let isPremium = document?.data()?["isPremium"] as? Bool ?? false
            
            // Premium users get unlimited queries
            if isPremium {
                completion(true)
                return
            }
            
            let queriesUsed = document?.data()?["queries_\(today)"] as? Int ?? 0
            completion(queriesUsed < 3) // Allow max 3 queries per day for free users
        }
    }
    func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // Format as "2025-03-18"
        return formatter.string(from: Date())
    }
    
    func logQueryUsage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let today = getCurrentDateString()
        let userDocRef = db.collection("users").document(userId)
        
        db.runTransaction { transaction, errorPointer -> Any? in
            let userDoc: DocumentSnapshot
            do {
                userDoc = try transaction.getDocument(userDocRef)
            } catch {
                return nil
            }
            
            let queriesUsed = userDoc.data()?["queries_\(today)"] as? Int ?? 0
            transaction.updateData(["queries_\(today)": queriesUsed + 1], forDocument: userDocRef)
            
            return nil
        } completion: { _, error in  // <-- Fix: Add `_, error` instead of `error in`
            if let error = error {
                print("❌ Error logging query: \(error.localizedDescription)")
            } else {
                print("✅ Query usage logged successfully.")
            }
        }
        
    }
}

import UIKit

class SubscriptionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Upgrade to Lila Premium"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Enjoy unlimited queries, deeper insights, and exclusive features."
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        
        let subscribeButton = UIButton(type: .system)
        subscribeButton.setTitle("Subscribe Now", for: .normal)
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, subscribeButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }

    @objc private func subscribeTapped() {
        SubscriptionManager.shared.purchaseSubscription()
    }
}
