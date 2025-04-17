import Foundation
import UIKit



enum AskLilaCategory: String, CaseIterable {
    case selfInsight
    case dateInsight
    case relationship
    case southNode
}


enum SubscriptionLevel {
    case trial    // Non-subscribers with limited trial usage
    case full     // Subscribers with full access
    case premium  // Subscribers with premium access
}

class AccessManager {
    static let shared = AccessManager()
    
    private init() {
        // Initialize the first time - check if we need to set up the trial
        if currentLevel == .trial {
            TrialUsageManager.shared.initializeTrialIfNeeded()
        }
    }
    
    private(set) var currentLevel: SubscriptionLevel = .trial

    func updateLevel(to level: SubscriptionLevel) {
        let oldLevel = currentLevel
        currentLevel = level
        
        // Log the change for debugging
        if oldLevel != level {
            print("🔄 Subscription level changed: \(oldLevel) -> \(level)")
        }
    }

    func canUse(_ category: AskLilaCategory) -> Bool {
        switch currentLevel {
        case .premium:
            return true  // Premium subscribers have unlimited access to everything
        case .full:
            return FullAccessManager.shared.canUse(category)  // Full access with their limits
        case .trial:
            return TrialUsageManager.shared.canUse(category)  // Trial users with trial limits
        }
    }

    func increment(_ category: AskLilaCategory) {
        switch currentLevel {
        case .premium:
            break  // No need to track usage for premium
        case .full:
            FullAccessManager.shared.increment(category)
        case .trial:
            TrialUsageManager.shared.increment(category)
        }
    }

    func remainingUses(for category: AskLilaCategory) -> Int? {
        switch currentLevel {
        case .premium:
            return nil  // Unlimited
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

    func isTrialActive() -> Bool {
        initializeTrialIfNeeded()
        return isInSneakPeekPeriod || remainingUses(for: .selfInsight) > 0
    }

    func canUse(_ category: AskLilaCategory) -> Bool {
        // If in 24-hour sneak peek period, allow unlimited access
        if isInSneakPeekPeriod {
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
class TrialBannerView: UIView {
    private let messageLabel = UILabel()
    private let remainingTimeLabel = UILabel()
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
        backgroundColor = UIColor(red: 0.47, green: 0.53, blue: 0.25, alpha: 0.9) // Lila olive green
        layer.cornerRadius = 8
        
        // Setup message label
        messageLabel.text = "✨ 24-Hour Unlimited Sneak Peek ✨"
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup remaining time label
        remainingTimeLabel.text = "All features unlocked! Loading time remaining..."
        remainingTimeLabel.font = UIFont.systemFont(ofSize: 13)
        remainingTimeLabel.textColor = .white
        remainingTimeLabel.textAlignment = .center
        remainingTimeLabel.numberOfLines = 0
        remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(messageLabel)
        addSubview(remainingTimeLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            remainingTimeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            remainingTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            remainingTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            remainingTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func startCountdown(endDate: Date) {
        self.endDate = endDate
        updateCountdown()
        
        // Create a timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        guard let endDate = endDate else { return }
        
        let now = Date()
        if now >= endDate {
            remainingTimeLabel.text = "Sneak peek has ended. Subscribe for full access!"
            timer?.invalidate()
            return
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now, to: endDate)
        if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
            remainingTimeLabel.text = String(format: "All features unlocked! %02d:%02d:%02d remaining", hours, minutes, seconds)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
