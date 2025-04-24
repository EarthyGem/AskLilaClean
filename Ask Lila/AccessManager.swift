import Foundation
import UIKit


import Foundation
import UIKit

enum AskLilaCategory: String, CaseIterable {
    case selfInsight
    case dateInsight
    case relationship
    case southNode
}

enum SubscriptionLevel {
    case trial             // Trial user (active sneak peek or still has uses)
    case trialExpired      // Trial user, but no access left
    case full
    case premium
    case introOffer
}


class AccessManager {
    static let shared = AccessManager()

    private init() {
        if currentLevel == .trial {
            TrialUsageManager.shared.initializeTrialIfNeeded()
        }
    }

    private(set) var currentLevel: SubscriptionLevel = .trial

    func updateLevel(to level: SubscriptionLevel) {
        let oldLevel = currentLevel
        currentLevel = level

        if oldLevel != level {
            print("🔄 Subscription level changed: \(oldLevel) -> \(level)")
        }
    }

    func canUse(_ category: AskLilaCategory) -> Bool {
        switch currentLevel {
        case .premium, .introOffer:
            return true  // Unlimited access
        case .full:
            return FullAccessManager.shared.canUse(category)
        case .trial:
            return TrialUsageManager.shared.canUse(category)
        case .trialExpired:
            return false  // 🚫 No access
        }
    }

    func increment(_ category: AskLilaCategory) {
        switch currentLevel {
        case .premium, .introOffer, .trialExpired:
            break  // No tracking needed or access denied
        case .full:
            FullAccessManager.shared.increment(category)
        case .trial:
            TrialUsageManager.shared.increment(category)
        }
    }

    func remainingUses(for category: AskLilaCategory) -> Int? {
        switch currentLevel {
        case .premium, .introOffer, .trialExpired:
            return nil  // Not relevant or no access
        case .full:
            return FullAccessManager.shared.remainingUses(for: category)
        case .trial:
            return TrialUsageManager.shared.remainingUses(for: category)
        }
    }
}

class FullAccessManager {
    static let shared = FullAccessManager()

    private let calendar = Calendar.current
    private let usageKeyPrefix = "fullAccessUsage_"
    private let quotaStartKey = "fullAccessQuotaStart"
    
    private let weeklyLimits: [AskLilaCategory: Int] = [
        .relationship: 3,
        .southNode: 2,
        .selfInsight: Int.max,
        .dateInsight: Int.max
    ]

    private var defaults: UserDefaults { .standard }

    private var quotaStartDate: Date {
        if let stored = defaults.object(forKey: quotaStartKey) as? Date,
           calendar.isDateInThisWeek(stored) {
            return stored
        }
        let now = Date()
        defaults.set(now, forKey: quotaStartKey)
        for cat in AskLilaCategory.allCases {
            defaults.set(0, forKey: usageKeyPrefix + cat.rawValue)
        }
        return now
    }

    private func resetIfNeeded() {
        if !calendar.isDateInThisWeek(quotaStartDate) {
            defaults.set(Date(), forKey: quotaStartKey)
            for cat in AskLilaCategory.allCases {
                defaults.set(0, forKey: usageKeyPrefix + cat.rawValue)
            }
        }
    }

    func canUse(_ category: AskLilaCategory) -> Bool {
        resetIfNeeded()
        return usageCount(for: category) < (weeklyLimits[category] ?? Int.max)
    }

    func usageCount(for category: AskLilaCategory) -> Int {
        defaults.integer(forKey: usageKeyPrefix + category.rawValue)
    }

    func remainingUses(for category: AskLilaCategory) -> Int {
        resetIfNeeded()
        return max(0, (weeklyLimits[category] ?? Int.max) - usageCount(for: category))
    }

    func increment(_ category: AskLilaCategory) {
        let key = usageKeyPrefix + category.rawValue
        let current = usageCount(for: category)
        defaults.set(current + 1, forKey: key)
    }
}

class TrialUsageManager {
    static let shared = TrialUsageManager()

    private let calendar = Calendar.current
    private let maxUsage: [AskLilaCategory: Int] = [
        .selfInsight: 3,
        .dateInsight: 2,
        .relationship: 2,
        .southNode: 1
    ]
    
    private let trialStartKey = "trialStartDate"
    private let lastResetKey = "trialLastReset"
    private let usageKeyPrefix = "trialUsage_"
    
    private var defaults: UserDefaults { .standard }

    var trialStartDate: Date? {
        get { defaults.object(forKey: trialStartKey) as? Date }
        set { defaults.set(newValue, forKey: trialStartKey) }
    }
    
    var trialEndDate: Date? {
        guard let startDate = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .hour, value: 24, to: startDate)
    }
    
    var remainingTrialTime: TimeInterval? {
        guard let endDate = trialEndDate else { return nil }
        return endDate.timeIntervalSince(Date())
    }
    
    var isInSneakPeekPeriod: Bool {
        guard let startDate = trialStartDate, let endDate = trialEndDate else { return false }
        let now = Date()

        print("🧪 Trial Check — Now: \(now)")
        print("📅 Start: \(startDate)")
        print("📅 End: \(endDate)")
        print("🔍 In Sneak Peek? \(now >= startDate && now < endDate)")

        return now >= startDate && now < endDate
    }

    // Initialize trial start date if not already set
    func initializeTrialIfNeeded() {
        if trialStartDate == nil {
            trialStartDate = Date()
            print("🆕 Trial started: \(trialStartDate!)")
        }
    }

    private func resetIfNeeded() {
        if let lastReset = defaults.object(forKey: lastResetKey) as? Date,
           calendar.isDateInToday(lastReset) {
            return
        }
        for cat in AskLilaCategory.allCases {
            defaults.set(0, forKey: usageKeyPrefix + cat.rawValue)
        }
        defaults.set(Date(), forKey: lastResetKey)
    }

    // Modified version of isTrialActive that's more robust
    func isTrialActive() -> Bool {
        initializeTrialIfNeeded()
        
        // First check if in sneak peek period
        if isInSneakPeekPeriod {
            print("✅ Trial active: User is in sneak peek period")
            return true
        }
        
        // If not in sneak peek, check if any categories still have remaining uses
        for category in AskLilaCategory.allCases {
            if remainingUses(for: category) > 0 {
                print("✅ Trial active: User has remaining uses for \(category.rawValue)")
                return true
            }
        }
        
        // If reached here, trial is not active
        print("🚫 Trial inactive: Sneak peek ended and no remaining uses")
        return false
    }
    func canUse(_ category: AskLilaCategory) -> Bool {
        // If in 24-hour sneak peek period, allow unlimited access
        if isInSneakPeekPeriod {
            print("🧪 Checking trial status. In sneak peek: \(isInSneakPeekPeriod), Remaining uses: \(remainingUses(for: category))")

            return true
        }
        
        // Otherwise, use regular trial limits
        resetIfNeeded()
        return remainingUses(for: category) > 0 && isTrialActive()
    }

    func increment(_ category: AskLilaCategory) {
        // Don't count usage during sneak peek period
        if isInSneakPeekPeriod {
            return
        }
        
        guard canUse(category) else { return }
        let key = usageKeyPrefix + category.rawValue
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }

    func remainingUses(for category: AskLilaCategory) -> Int {
        // If in sneak peek period, return unlimited (high number)
        if isInSneakPeekPeriod {
            return 999
        }
        
        resetIfNeeded()
        let used = defaults.integer(forKey: usageKeyPrefix + category.rawValue)
        return max(0, maxUsage[category]! - used)
    }
}
extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        let now = Date()
        guard let startOfWeek = self.dateInterval(of: .weekOfYear, for: now)?.start else {
            return false
        }
        guard let endOfWeek = self.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return false
        }
        return (date >= startOfWeek && date < endOfWeek)
    }
}
import UIKit

class TrialBannerView: UIView {

    enum BannerMode {
        case sneakPeek(endDate: Date)
        case introOffer
        case trialExpired
        case full
        case premium
    }


    var onDismiss: (() -> Void)?  // Called when user taps ✖️

    private let messageLabel = UILabel()
    private let remainingTimeLabel = UILabel()
    private let dismissButton = UIButton(type: .system)

    private var timer: Timer?
    private var endDate: Date?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 0.9)
        layer.cornerRadius = 8

        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .left
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        remainingTimeLabel.font = UIFont.systemFont(ofSize: 13)
        remainingTimeLabel.textColor = .white
        remainingTimeLabel.textAlignment = .left
        remainingTimeLabel.numberOfLines = 0
        remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        dismissButton.setTitle("✖️", for: .normal)
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        addSubview(messageLabel)
        addSubview(remainingTimeLabel)
        addSubview(dismissButton)

        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            dismissButton.widthAnchor.constraint(equalToConstant: 30),
            dismissButton.heightAnchor.constraint(equalToConstant: 30),

            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -8),

            remainingTimeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            remainingTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            remainingTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            remainingTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    func configure(for mode: BannerMode) {
        switch mode {
        case .sneakPeek(let endDate):
            messageLabel.text = "✨ 24-Hour Unlimited Sneak Peek ✨"
            self.endDate = endDate
            startCountdown()

        case .trialExpired:
            messageLabel.text = "🚪 Trial Ended"
            remainingTimeLabel.text = "Your free trial has ended. Subscribe for full access."


        case .introOffer:
            messageLabel.text = "🎁 3-Day Premium Trial"
            remainingTimeLabel.text = "You're enjoying a Premium preview. Unlimited access unlocked!"
            stopCountdown()

        case .full:
            messageLabel.text = "🌿 Full Access Active"
            remainingTimeLabel.text = "You’re currently subscribed to the Full plan. Upgrade anytime for unlimited access."
            stopCountdown()

        case .premium:
            messageLabel.text = "💫 Premium Access Active"
            remainingTimeLabel.text = "You're enjoying Premium features with unlimited access to all insights."
            stopCountdown()
        }
    }

    private func startCountdown() {
        updateCountdown()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }

    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    private func updateCountdown() {
        guard let endDate = endDate else { return }

        let now = Date()
        if now >= endDate {
            remainingTimeLabel.text = "Sneak peek has ended. Subscribe for full access!"
            stopCountdown()
            return
        }

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: endDate)
        if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
            remainingTimeLabel.text = String(format: "All features unlocked! %02d:%02d:%02d remaining", hours, minutes, seconds)
        }
    }

    @objc private func dismissTapped() {
        stopCountdown()
        self.removeFromSuperview()
        onDismiss?()
    }

    deinit {
        stopCountdown()
    }
}
extension TrialUsageManager {
    
    // Add a new method to forcefully expire the trial
    func forceExpireTrial() {
        // 1. Set the trial start date to a time well in the past
        let expiredStartDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        trialStartDate = expiredStartDate
        
        // 2. Set all usage counters to their maximum values
        for category in AskLilaCategory.allCases {
            let key = usageKeyPrefix + category.rawValue
            let maxUsageForCategory = maxUsage[category] ?? 0
            defaults.set(maxUsageForCategory, forKey: key)
        }
        
        print("🚫 Trial forcefully expired: sneak peek ended and all usage quotas reached")
    }
    
   
    
    // Helper to check if any category has remaining uses
    func hasAnyRemainingUses() -> Bool {
        for category in AskLilaCategory.allCases {
            if remainingUses(for: category) > 0 {
                return true
            }
        }
        return false
    }
    
    // Debug method to print the current trial status
    func printTrialStatus() {
        let now = Date()
        print("📊 TRIAL STATUS REPORT:")
        print("🧪 Current time: \(now)")
        
        if let start = trialStartDate {
            print("📅 Trial started: \(start)")
            if let end = trialEndDate {
                print("📅 Trial ends: \(end)")
                print("⏳ In sneak peek: \(now < end)")
            } else {
                print("⚠️ Trial end date is nil")
            }
        } else {
            print("⚠️ Trial start date is nil")
        }
        
        // Print remaining uses for each category
        print("🔢 REMAINING USES:")
        for category in AskLilaCategory.allCases {
            let remaining = remainingUses(for: category)
            let max = maxUsage[category] ?? 0
            print("- \(category.rawValue): \(remaining)/\(max)")
        }
        
        print("📱 Is trial active: \(isTrialActive())")
    }
}

// MARK: - AccessManager Extension
extension AccessManager {
    
    // Add a method to check if access is truly expired
    func refreshSubscriptionStatus() {
        // First check for paid subscriptions
        // This would typically involve checking with StoreKit
        // For simplicity in this fix, we'll focus on the trial logic
        
        let trialManager = TrialUsageManager.shared
        
        // Get accurate trial status
        let isInSneakPeek = trialManager.isInSneakPeekPeriod
        let hasRemainingUses = trialManager.hasAnyRemainingUses()
        
        // Update subscription level based on accurate status
        if isInSneakPeek || hasRemainingUses {
            updateLevel(to: .trial)
        } else {
            updateLevel(to: .trialExpired)
        }
        
        print("🔄 Subscription level after refresh: \(currentLevel)")
    }
    
    // Add a debug method
    func printAccessStatus() {
        print("🔐 ACCESS STATUS REPORT:")
        print("📱 Current level: \(currentLevel)")
        
        // Print access status for each category
        print("🔑 ACCESS BY CATEGORY:")
        for category in AskLilaCategory.allCases {
            let hasAccess = canUse(category)
            let remaining = remainingUses(for: category)
            print("- \(category.rawValue): \(hasAccess ? "✅" : "🚫") \(remaining != nil ? "(\(remaining!) left)" : "")")
        }
    }
}
