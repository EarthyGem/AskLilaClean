import Foundation

enum SubscriptionLevel {
    case trial
    case full
    case premium
}

enum AskLilaCategory: String, CaseIterable {
    case selfInsight
    case dateInsight
    case relationship
    case southNode
}


    class AccessManager {
        static let shared = AccessManager()
        
        private init() {}
        
        private(set) var currentLevel: SubscriptionLevel = .trial

        func updateLevel(to level: SubscriptionLevel) {
            currentLevel = level
        }
    


    func canUse(_ category: AskLilaCategory) -> Bool {
        switch currentLevel {
        case .premium:
            return true
        case .full:
            return FullAccessManager.shared.canUse(category)
        case .trial:
            return TrialUsageManager.shared.canUse(category)
        }
    }

    func increment(_ category: AskLilaCategory) {
        switch currentLevel {
        case .premium:
            break
        case .full:
            FullAccessManager.shared.increment(category)
        case .trial:
            TrialUsageManager.shared.increment(category)
        }
    }

    func remainingUses(for category: AskLilaCategory) -> Int? {
        switch currentLevel {
        case .premium:
            return nil
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
        guard let start = trialStartDate else { return false }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day! < 3
    }

    func canUse(_ category: AskLilaCategory) -> Bool {
        resetIfNeeded()
        return remainingUses(for: category) > 0 && isTrialActive()
    }

    func increment(_ category: AskLilaCategory) {
        guard canUse(category) else { return }
        let key = usageKeyPrefix + category.rawValue
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }

    func remainingUses(for category: AskLilaCategory) -> Int {
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
