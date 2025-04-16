//
//  LilaIntel.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/31/25.
//

import Foundation
import SwiftEphemeris
import FirebaseAuth
import FirebaseFirestore

func generateChartSummary(from cake: ChartCake, focusHouse: Int? = nil) -> ChartSummary {
    let natal = cake.natal
    let adjectiveArrays: [String: [String]] = [
        "Aries": ["Fiery", "Bold", "Courageous", "Pioneering", "Energetic", "Passionate", "Competitive"],
        "Taurus": ["Grounded", "Peace-loving", "Patient", "Steadfast", "Dependable", "Practical", "Stable"],
        "Gemini": ["Witty", "Versatile", "Curious", "Adaptable", "Communicative", "Playful", "Perceptive"],
        "Cancer": ["Caring", "Nurturing", "Sensitive", "Protective", "Supportive", "Compassionate", "Empathetic"],
        "Leo": ["Dignified", "Charismatic", "Generous", "Confident", "Dramatic", "Proud", "Passionate"],
        "Virgo": ["Analytical", "Practical", "Diligent", "Meticulous", "Modest", "Organized", "Thoughtful"],
        "Libra": ["Charming", "Harmonious", "Diplomatic", "Balanced", "Artistic", "Fair", "Idealistic"],
        "Scorpio": ["Intense", "Passionate", "Resourceful", "Determined", "Powerful", "Transformative", "Mysterious"],
        "Sagittarius": ["Adventurous", "Philosophical", "Optimistic", "Freedom-loving", "Enthusiastic", "Wise", "Expansive"],
        "Capricorn": ["Ambitious", "Disciplined", "Practical", "Serious", "Responsible", "Determined", "Patient"],
        "Aquarius": ["Innovative", "Eccentric", "Humanitarian", "Independent", "Rebellious", "Progressive", "Original"],
        "Pisces": ["Compassionate", "Sensitive", "Imaginative", "Spiritual", "Dreamy", "Intuitive", "Mystical"]
    ]

    let planetArrays: [String: [String]] = [
        "Sun": ["Creator", "Star", "Leader"],
        "Moon": ["Nurturer", "Provider", "Healer", "Caregiver"],
        "Mercury": ["Thinker", "Storyteller", "Messenger", "Intellectual", "Teacher"],
        "Venus": ["Harmonizer","Socialite", "Artist", "Connector", "Lover", "Peacemaker"],
        "Mars": ["Warrior", "Builder", "Protector", "Pioneer", "Fighter"],
        "Jupiter": ["Philosopher", "Explorer", "Benefactor", "Bestower of Blessings", "Preacher", "Know-it-all"],
        "Saturn": ["Organizer", "Strategist", "Planner", "Fun Sponge"],
        "Uranus": ["Awakener", "Renegade", "Innovator", "Agent of Change", "Disruptor"],
        "Neptune": ["Dreamer", "Visionary", "Idealist", "Artist"],
        "Pluto": ["Transformer", "Alchemist", "Revealer", "Psychotherapist"]
    ]

    // 🌟 Strongest Planets
    let sortedPlanets = cake.planetScores.sorted { $0.value > $1.value }
    let top3Planets = sortedPlanets.prefix(3).map { $0.key }

    // 🔤 Archetypes using adjectiveArrays and planetArrays
    let planetArchetypes = top3Planets.compactMap { planet -> String? in
        guard let coord = natal.planets.first(where: { $0.body == planet }) else { return nil }
        let signName = coord.sign.keyName
        let planetName = planet.keyName

        guard let adjectives = adjectiveArrays[signName], let nouns = planetArrays[planetName] else {
            return nil
        }

        let adjective = adjectives.randomElement() ?? signName
        let noun = nouns.randomElement() ?? planetName
        return "\(adjective) \(noun)"
    }

    // ☀️🌙⬆️ Core Trinity
    let sun = natal.sun.body
    let moon = natal.moon.body
    let rising = natal.ascendantCoordinate.body

    // 🔥 Motivations (Strongest Signs)
    let topSigns = cake.signScores.sorted { $0.value > $1.value }.prefix(2).map { $0.key }

    // 🏠 Life Emphasis (Strongest Houses)
    let topHouses = cake.houseScores.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

    // 🔍 House Activations (Transits & Progressions to House Rulers)
    let houseActivationAspectStrings: [String]
    if let house = focusHouse {
        let aspectString = cake.calculateAllMovingAspectsToRulers(of: house)
        houseActivationAspectStrings = [aspectString]
    } else {
        houseActivationAspectStrings = []
    }

    // 🌀 Poetic Element & Modality Scores
    let elementScores = calculateTotalElementScores(signScores: cake.signScores)
    let modalityScores = calculateTotalModalityScores(signScores: cake.signScores)

    return ChartSummary(
        strongestPlanets: top3Planets.compactMap {$0.planet?.keyName},
        planetArchetypes: planetArchetypes,
        sun: sun,
        moon: moon,
        rising: sun,
        strongestSigns: topSigns.compactMap {$0.keyName},
        strongestHouses: topHouses,
        houseUserAskedAbout: focusHouse,
        houseTransitsAndProgressions: houseActivationAspectStrings,
        astrodynesByElement: elementScores,
        astrodynesByModality: modalityScores
    )
}

let elementMapping: [Zodiac: Element] = [
    .aries: .enthusiasm, .leo: .enthusiasm, .sagittarius: .enthusiasm,
    .taurus: .practicality, .virgo: .practicality, .capricorn: .practicality,
    .gemini: .conceptualization, .libra: .conceptualization, .aquarius: .conceptualization,
    .cancer: .emotion, .scorpio: .emotion, .pisces: .emotion
]

let modalityMapping: [Zodiac: Modality] = [
    .aries: .pioneer, .cancer: .pioneer, .libra: .pioneer, .capricorn: .pioneer,
    .taurus: .perfector, .leo: .perfector, .scorpio: .perfector, .aquarius: .perfector,
    .gemini: .developer, .virgo: .developer, .sagittarius: .developer, .pisces: .developer
]


func calculateTotalElementScores(signScores: [Zodiac: Double]) -> [Element: Double] {
    var scores: [Element: Double] = [:]
    for (sign, score) in signScores {
        let element = elementMapping[sign]!
        scores[element, default: 0] += score
    }
    return scores
}

func calculateTotalModalityScores(signScores: [Zodiac: Double]) -> [Modality: Double] {
    var scores: [Modality: Double] = [:]
    for (sign, score) in signScores {
        let modality = modalityMapping[sign]!
        scores[modality, default: 0] += score
    }
    return scores
}

func logChartSummaryToFirestore(_ summary: ChartSummary, for question: String? = nil) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    var data: [String: Any] = [
        "strongestPlanets": summary.planetArchetypes,
        "sun": summary.sun,
        "moon": summary.moon,
        "rising": summary.rising,
        "strongestSigns": summary.strongestSigns.map { $0 },
        "strongestHouses": summary.strongestHouses,
        "focusHouse": summary.houseUserAskedAbout ?? -1,
        "timestamp": Date().timeIntervalSince1970,
        "elementScores": summary.astrodynesByElement.mapValues { round($0 * 100) / 100 },
        "modalityScores": summary.astrodynesByModality.mapValues { round($0 * 100) / 100 },
        "activations": summary.houseTransitsAndProgressions.map { $0 }
    ]
    
    if let question = question {
        data["question"] = question
    }

    Firestore.firestore()
        .collection("users")
        .document(uid)
        .collection("chartSummaries")
        .addDocument(data: data)
}

func generateChartContextPrompt(from summary: ChartSummary) -> String {
    var context = "The user’s natal chart reveals the following patterns. Use this as context to guide tone, symbolism, and timing, but do not repeat it back unless asked:\n\n"

    if !summary.planetArchetypes.isEmpty {
        context += "🌟 Strongest Planetary Archetypes: \(summary.planetArchetypes.joined(separator: ", "))\n"
    }

    if !summary.strongestSigns.isEmpty {
        let signNames = summary.strongestSigns.map { $0 }
        context += "🔥 Motivated by: \(signNames.joined(separator: ", "))\n"
    }

    if !summary.strongestHouses.isEmpty {
        let houseNums = summary.strongestHouses.map { "House \($0)" }
        context += "🏠 Life themes concentrate in: \(houseNums.joined(separator: ", "))\n"
    }

    if let focused = summary.houseUserAskedAbout {
        context += "🧭 Current focus: House \(focused) (user asked about this)\n"
    }

    if !summary.astrodynesByElement.isEmpty {
        let breakdown = summary.astrodynesByElement.map { "\($0.key): \(Int($0.value))" }.joined(separator: ", ")
        context += "🌱 Elemental Balance (Astrodynes): \(breakdown)\n"
    }

    if !summary.astrodynesByModality.isEmpty {
        let breakdown = summary.astrodynesByModality.map { "\($0.key): \(Int($0.value))" }.joined(separator: ", ")
        context += "📊 Modal Focus (Astrodynes): \(breakdown)\n"
    }

    // Optional: Include most recent activations
    if !summary.houseTransitsAndProgressions.isEmpty {
        context += "🚀 Active Transits/Progressions to house \(summary.houseUserAskedAbout ?? 0): \(summary.houseTransitsAndProgressions.prefix(2))\n"
    }

    return context
}




func logActivationDetail(
    for aspect: CelestialAspect,
    in cake: ChartCake,
    using metric: PowerMetrics
) -> [String: Any] {
    
    let adjectiveArrays: [String: [String]] = [
        "Aries": ["Fiery", "Bold", "Courageous", "Pioneering", "Energetic", "Passionate", "Competitive"],
        "Taurus": ["Grounded", "Peace-loving", "Patient", "Steadfast", "Dependable", "Practical", "Stable"],
        "Gemini": ["Witty", "Versatile", "Curious", "Adaptable", "Communicative", "Playful", "Perceptive"],
        "Cancer": ["Caring", "Nurturing", "Sensitive", "Protective", "Supportive", "Compassionate", "Empathetic"],
        "Leo": ["Dignified", "Charismatic", "Generous", "Confident", "Dramatic", "Proud", "Passionate"],
        "Virgo": ["Analytical", "Practical", "Diligent", "Meticulous", "Modest", "Organized", "Thoughtful"],
        "Libra": ["Charming", "Harmonious", "Diplomatic", "Balanced", "Artistic", "Fair", "Idealistic"],
        "Scorpio": ["Intense", "Passionate", "Resourceful", "Determined", "Powerful", "Transformative", "Mysterious"],
        "Sagittarius": ["Adventurous", "Philosophical", "Optimistic", "Freedom-loving", "Enthusiastic", "Wise", "Expansive"],
        "Capricorn": ["Ambitious", "Disciplined", "Practical", "Serious", "Responsible", "Determined", "Patient"],
        "Aquarius": ["Innovative", "Eccentric", "Humanitarian", "Independent", "Rebellious", "Progressive", "Original"],
        "Pisces": ["Compassionate", "Sensitive", "Imaginative", "Spiritual", "Dreamy", "Intuitive", "Mystical"]
    ]

    let planetArrays: [String: [String]] = [
        "Sun": ["Creator", "Star", "Leader"],
        "Moon": ["Nurturer", "Provider", "Healer", "Caregiver"],
        "Mercury": ["Thinker", "Storyteller", "Messenger", "Intellectual", "Teacher"],
        "Venus": ["Harmonizer","Socialite", "Artist", "Connector", "Lover", "Peacemaker"],
        "Mars": ["Warrior", "Builder", "Protector", "Pioneer", "Fighter"],
        "Jupiter": ["Philosopher", "Explorer", "Benefactor", "Bestower of Blessings", "Preacher", "Know-it-all"],
        "Saturn": ["Organizer", "Strategist", "Planner", "Fun Sponge"],
        "Uranus": ["Awakener", "Renegade", "Innovator", "Agent of Change", "Disruptor"],
        "Neptune": ["Dreamer", "Visionary", "Idealist", "Artist"],
        "Pluto": ["Transformer", "Alchemist", "Revealer", "Psychotherapist"]
    ]
 
        let natal = cake.natal
        let body1 = aspect.body1
        let body2 = aspect.body2

        let body1Cusp = natal.houseCusps.house(of: body1)
        let body2Cusp = natal.houseCusps.house(of: body2)

        let body1Rulerships = natal.cuspsRuled(by: body1.body.planet ?? .sun).map { $0.number }
        let body2Rulerships = natal.cuspsRuled(by: body2.body.planet ?? .sun).map { $0.number }

        let sign1 = body1.sign.keyName
        let sign2 = body2.sign.keyName

    let element1 = elementMapping[body1.sign].debugDescription ?? "Unknown"
        let element2 = elementMapping[body2.sign].debugDescription ?? "Unknown"
        let modality1 = modalityMapping[body1.sign].debugDescription ?? "Unknown"
    let modality2 = modalityMapping[body2.sign].debugDescription ?? "Unknown"

        let progressionType1 = aspect.body1ProgressionType
        let progressionType2 = aspect.body2ProgressionType

        let archetype1 = "\(body1.sign.keyName) \(body1.body.keyName)"
        let archetype2 = "\(body2.sign.keyName) \(body2.body.keyName)"

        let variance: VarianceMetrics = (
            harmony: metric.harmony,
            discord: metric.discord,
            netHarmony: metric.netHarmony
        )

        return [
            "aspect": aspect.kind,
            "progressionType": [
                "from": progressionType1,
                "to": progressionType2
            ],
            "bodies": [
                "from": [
                    "name": body1.body.keyName,
                    "sign": sign1,
                    "house": body1Cusp.number,
                    "element": element1,
                    "modality": modality1,
                    "rulerships": body1Rulerships,
                    "archetype": archetype1
                ],
                "to": [
                    "name": body2.body.keyName,
                    "sign": sign2,
                    "house": body2Cusp.number,
                    "element": element2,
                    "modality": modality2,
                    "rulerships": body2Rulerships,
                    "archetype": archetype2
                ]
            ],
            "scores": [
                "score": metric.power,
                "harmony": metric.harmony,
                "discord": metric.discord,
                "netHarmony": metric.netHarmony
            ],
            "summaryText": aspect.rickysPowerString(
                with: natal,
                metric.power,
                body1: body1,
                body2: body2,
                aspectKeywords: aspect.rickysAspectKeyword,
                tuple: variance
            ),
            "basicString": aspect.basicAspectString(with: natal),
            "timestamp": Date().timeIntervalSince1970
        ]
    }

enum Element {
    case enthusiasm     // Fire
    case practicality   // Earth
    case conceptualization // Air
    case emotion        // Water
}



enum Modality {
    case pioneer     // Cardinal
    case perfector   // Fixed
    case developer   // Mutable
}


class ChartContextManager {
    static let shared = ChartContextManager()

    private init() {}

    func storeChartSummary(_ summary: ChartSummary, for uid: String) {
        let data = summary.toFirestoreDict() // We'll define this
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("chartContext")
            .document("summary")
            .setData(data, merge: true)
    }

    func updateHouseSignifications(_ house: Int, significations: [String], for uid: String) {
        let update: [String: Any] = [
            "houseSignifications.\(house)": FieldValue.arrayUnion(significations)
        ]
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("chartContext")
            .document("summary")
            .setData(update, merge: true)
    }

    func fetchChartSummary(for uid: String, completion: @escaping (ChartSummary?) -> Void) {
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("chartContext")
            .document("summary")
            .getDocument(completion: { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    completion(nil)
                    return
                }
                if let summary = ChartSummary(data: data) {
                    completion(summary)
                } else {
                    completion(nil)
                }

            })
// ← You define this init
            
    }
}

struct ChartSummary {
    let strongestPlanets: [String]
    let planetArchetypes: [String] // e.g., “Visionary Healer”
    let sun: CelestialObject
    let moon: CelestialObject
    let rising: CelestialObject
    let strongestSigns: [String]
    let strongestHouses: [Int]
    let houseUserAskedAbout: Int?
    let houseTransitsAndProgressions: [String]
    let astrodynesByElement: [Element: Double]
    let astrodynesByModality: [Modality: Double]
    var houseSignifications: [Int: [String]]?
}

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }

    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
extension ChartSummary {
    func toFirestoreDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // 🌟 Archetypes
        dict["planetArchetypes"] = planetArchetypes
        
        // ☀️🌙⬆️ Core Trinity
        dict["sun"] = sun
        dict["moon"] = moon
        dict["rising"] = rising
        
        // 🔥 Motivations
        dict["strongestSigns"] = strongestSigns.map { $0 }
        
        // 🪐 Strongest Planets
        dict["strongestPlanets"] = strongestPlanets.map { $0 }
        
        // 🏠 Life Emphasis
        dict["strongestHouses"] = strongestHouses
        
        // 🧭 Focused House
        if let house = houseUserAskedAbout {
            dict["houseUserAskedAbout"] = house
        }
        
        // 🚀 Activations
        if !houseTransitsAndProgressions.isEmpty {
            dict["houseTransitsAndProgressions"] = houseTransitsAndProgressions
        }

        // 🌀 Element Balance
        dict["astrodynesByElement"] = astrodynesByElement.mapKeys { $0 }

        // 📊 Modal Balance
        dict["astrodynesByModality"] = astrodynesByModality.mapKeys { $0 }

        // 🧠 Ongoing Refinement – House Significations
        if let houseSigs = houseSignifications, !houseSigs.isEmpty {
            dict["houseSignifications"] = houseSigs.mapKeys { "\($0)" }
        }

        // 🕒 Timestamp for versioning/debugging
        dict["timestamp"] = Date().timeIntervalSince1970
        
        return dict
    }
}
extension ChartSummary {
    init?(data: [String: Any]) {
        guard
            let strongestPlanetsRaw = data["strongestPlanets"] as? [String],
            let planetArchetypes = data["planetArchetypes"] as? [String],
            let sunRaw = data["sun"] as? String,
            let moonRaw = data["moon"] as? String,
            let risingRaw = data["rising"] as? String,
            let strongestSignsRaw = data["strongestSigns"] as? [String],
            let strongestHouses = data["strongestHouses"] as? [Int],
            let houseTransitsAndProgressions = data["houseTransitsAndProgressions"] as? [String],
            let astrodynesByElementRaw = data["astrodynesByElement"] as? [String: Double],
            let astrodynesByModalityRaw = data["astrodynesByModality"] as? [String: Double]
        else {
            return nil
        }

        
        self.planetArchetypes = planetArchetypes
        self.sun = CelestialObject.planet(.sun)
        self.moon = CelestialObject.planet(.moon)
        self.rising = CelestialObject.planet(.sun)
        
        self.strongestPlanets = strongestPlanetsRaw.compactMap { $0 }
        self.strongestSigns = strongestSignsRaw.compactMap { $0 }

        self.astrodynesByElement = astrodynesByElementRaw.compactMapKeys { elementFromString($0) }
        self.astrodynesByModality = astrodynesByModalityRaw.compactMapKeys { modalityFromString($0) }

        self.strongestHouses = strongestHouses
        self.houseUserAskedAbout = data["houseUserAskedAbout"] as? Int
        self.houseTransitsAndProgressions = houseTransitsAndProgressions

      

        if let houseSignificationsRaw = data["houseSignifications"] as? [String: [String]] {
            let parsed = houseSignificationsRaw.compactMapKeys { Int($0) }
            self.houseSignifications = parsed
        } else {
            self.houseSignifications = nil
        }
    }
}
func elementFromString(_ string: String) -> Element? {
    switch string.lowercased() {
    case "enthusiasm": return .enthusiasm
    case "practicality": return .practicality
    case "conceptualization": return .conceptualization
    case "emotion": return .emotion
    default: return nil
    }
}

func modalityFromString(_ string: String) -> Modality? {
    switch string.lowercased() {
    case "pioneer": return .pioneer
    case "perfector": return .perfector
    case "developer": return .developer
    default: return nil
    }
}
