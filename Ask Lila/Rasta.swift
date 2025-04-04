//
//  Rasta.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/4/25.
//

import Foundation
import SwiftEphemeris
// MARK: - Soul Filters Derived from the Chart

struct UserCoreChartProfile {
    let strongestPlanet: CelestialObject
    let strongestPlanetSign: Zodiac
    let strongestPlanetHouse: Int
    let strongestPlanetTopAspect: NatalAspectScore?

    let strongestSign: Zodiac
    let strongestHouses: [Int]

    let sunSign: Zodiac
    let sunHouse: Int
    let topAspectToSun: NatalAspectScore?

    let moonSign: Zodiac
    let moonHouse: Int
    let topAspectToMoon: NatalAspectScore?

    let ascendantSign: Zodiac
    let topAspectToAscendant: NatalAspectScore?

    let mercurySign: Zodiac
    let mercuryHouse: Int

    let topAspectsToStrongestPlanet: [NatalAspectScore]
    let topAspectsToSun: [NatalAspectScore]
    let topAspectsToMoon: [NatalAspectScore]
    let topAspectsToAscendant: [NatalAspectScore]
}

struct UserChartProfile {
    let name: String
    let birthDate: Date
    let sex: ChartCake.Sex

    let strongestPlanet: CelestialObject
    let strongestPlanetSign: Zodiac
    let strongestPlanetHouse: Int
    let strongestPlanetRuledHouses: [Int]

    let sunSign: Zodiac
    let sunHouse: Int
    let sunPower: Double
    let topAspectsToSun: [NatalAspectScore]   // ✅ Added

    let moonSign: Zodiac
    let moonHouse: Int
    let moonPower: Double
    let topAspectsToMoon: [NatalAspectScore]

    let ascendantSign: Zodiac
    let ascendantPower: Double
    let topAspectsToAscendant: [NatalAspectScore]

    let mercurySign: Zodiac
    let mercuryHouse: Int

    let ascendantRulerSigns: [Zodiac]
    let ascendantRulers: [CelestialObject]
    let ascendantRulerHouses: [Int]
    let ascendantRulerPowers: [Double]
    let topAspectsToAscendantRulers: [NatalAspectScore]

    let dominantHouseScores: [Int: Double]
    let dominantSignScores: [Zodiac: Double]
    let dominantPlanetScores: [CelestialObject: Double]

    let mostHarmoniousPlanet: CelestialObject
    let mostDiscordantPlanet: CelestialObject

    let topAspectsToStrongestPlanet: [NatalAspectScore]
}
struct SoulValuesProfile {
    let coreSensitivity: String                  // What the soul instinctively protects and honors
    let spiritualNeed: String                    // What must be present for the user to feel purposeful
    let relationalValue: String                  // What the user values most in connection
    let perceptionLens: String                   // How they instinctively interpret life
    let primaryVirtueInDevelopment: String       // The soul's evolving strength or needed refinement
    let communicationMode: String                 // How the soul prefers to receive insight (from Mercury sign)
    let blossomingConditions: String // ideal nurturing sentiment (moon sign and house and aspects
    let radiancePath: String   // Where and how the user is learning to shine (from Sun sign + house)

    let cognitiveFocus: String                   // Life areas most attended to naturally (from Mercury house)
}


struct AlchemicalToneProfile {
    let soulFunction: String                     // Core spiritual capacity in refinement (from strongest planet)
    let lifeClimate: String                      // General energetic tone of the chart (from strongest sign)
    let developmentArena: String                 // Main field of life experience (from strongest house)
    let keyForces: [String]                      // Key aspect pressures shaping this evolution
    let primaryVirtues: [String]                 // Core virtues being forged by aspectal friction
    let preferredReception: String               // Tone and pacing the user will feel most supported by
    let symbolicVoiceTone: String?               // Optional guidance on metaphor or image style (Mercury+Moon-based)
}

struct RelationalSignature {
    let emotionalPace: String                    // How emotional truth is processed (aspects + Moon)
    let learningStyle: String                    // How new insight is best integrated (sign-based)
    let knownEdges: [String]                     // Potential shadows, sensitivities, or growth edges
    let knownGifts: [String]                     // Natural assets that can become strengths
}

struct UserContext {
    let strongestPlanet: String
    let strongestSign: String
    let strongestHouse: Int
    let topAspects: [String]
}
func buildSoulProfiles(from profile: UserChartProfile) -> (SoulValuesProfile, AlchemicalToneProfile, RelationalSignature) {

    let strongestPlanet = profile.strongestPlanet
    let strongestSign = profile.strongestPlanetSign
    let strongestHouse = profile.strongestPlanetHouse
    let topAspects = profile.topAspectsToStrongestPlanet
    let topMoonAspects = profile.topAspectsToMoon
    let moonSign = profile.moonSign
    // Mercury used for perception + style
    let mercurySign = profile.mercurySign
    let mercuryHouse = profile.mercuryHouse

    let sunSign = profile.sunSign
    let sunHouse = profile.sunHouse

    let soulValues = SoulValuesProfile(
        coreSensitivity: coreSensitivity(from: strongestPlanet.planet!),
        spiritualNeed: spiritualNeed(from: profile.ascendantSign),
        relationalValue: relationalValue(from: strongestPlanet, topAspects: topAspects),
        perceptionLens: perceptionLens(from: strongestSign),
        primaryVirtueInDevelopment: virtueInDevelopment(from: strongestPlanet, aspects: topAspects),

        communicationMode: communicationMode(from: mercurySign),
        blossomingConditions: blossomingConditions(from: moonSign, aspects: topMoonAspects),
        radiancePath: sunRadianceTheme(from: sunSign, sunHouse), // 🌞 new
        cognitiveFocus: cognitiveFocus(from: mercuryHouse),

      
    )

    // ---- ALCHEMICAL TONE FILTER ----
    let toneProfile = AlchemicalToneProfile(
        soulFunction: soulFunction(from: strongestPlanet),
        lifeClimate: signClimate(from: strongestSign),
        developmentArena: houseArena(from: strongestHouse),
        keyForces: keyForces(from: topAspects),
        primaryVirtues: derivedVirtues(from: strongestPlanet, topAspects: topAspects),
        preferredReception: preferredReception(from: profile),
        symbolicVoiceTone: symbolicTone(from: mercurySign, profile.moonSign)
    )

    // ---- RELATIONAL STYLE FILTER ----
    let relationalStyle = RelationalSignature(
        emotionalPace: emotionalPace(from: strongestPlanet, aspects: topAspects),
        learningStyle: learningStyle(from: strongestSign),
        knownEdges: knownEdges(from: profile),
        knownGifts: knownGifts(from: profile)
    )

    return (soulValues, toneProfile, relationalStyle)
}

func coreSensitivity(from planet: Planet) -> String {
    switch planet {
    case .moon: return "Emotional truth and safety"
    case .mercury: return "Mental clarity and understanding"
    case .venus: return "Relational harmony and inner beauty"
    case .saturn: return "Structure, maturity, earned trust"
    case .pluto: return "Emotional power and soul-level transformation"
    default: return "Authentic self-expression"
    }
}

func spiritualNeed(from ascSign: Zodiac) -> String {
    switch ascSign {
    case .virgo: return "To be competent, useful, and of service"
    case .leo: return "To express joy and radiance"
    case .capricorn: return "To build legacy through mastery"
    case .cancer: return "To feel safe, nurtured, and emotionally held"
    default: return "To grow in alignment with their inner calling"
    }
}
func sunRadianceTheme(from sign: Zodiac, _ house: Int) -> String {
    let signMessage: String = {
        switch sign {
        case .aries: return "by expressing initiative and embodying courage"
        case .taurus: return "through creating stability, beauty, and grounded presence"
        case .gemini: return "by sharing curiosity, ideas, and playful intelligence"
        case .cancer: return "through emotional sincerity, care, and intuitive strength"
        case .leo: return "by radiating joy, creativity, and warm-hearted leadership"
        case .virgo: return "by offering precise insight, service, and healing intention"
        case .libra: return "through harmonious connection, aesthetic refinement, and diplomacy"
        case .scorpio: return "by facing depth, transmuting pain, and revealing emotional truth"
        case .sagittarius: return "through sharing wisdom, faith, and adventurous vision"
        case .capricorn: return "by building, mastering, and embodying trustworthy presence"
        case .aquarius: return "through originality, systemic insight, and communal evolution"
        case .pisces: return "by dissolving boundaries and channeling compassion into form"
        }
    }()

    let houseMessage: String = {
        switch house {
        case 1: return "through personal authenticity and embodied presence"
        case 2: return "by building inner value and sharing resources with integrity"
        case 3: return "through communication, storytelling, and uplifting thought"
        case 4: return "by illuminating the emotional root and generational care"
        case 5: return "through play, creativity, and wholehearted expression"
        case 6: return "by refining systems, solving problems, and living devotion through detail"
        case 7: return "by radiating through relationship and building bridges between souls"
        case 8: return "through healing trauma, owning power, and inviting transformation"
        case 9: return "by sharing higher truths, vision, and cross-cultural wisdom"
        case 10: return "by offering leadership, legacy, and contribution to the world"
        case 11: return "through collective dreaming, innovation, and building future communities"
        case 12: return "by shining light into the unseen, the mystical, and the quietly divine"
        default: return "through the arena of House \(house)"
        }
    }()

    return "They are learning to shine \(signMessage), especially \(houseMessage)."
}

func communicationMode(from sign: Zodiac) -> String {
    switch sign {
    case .gemini: return "Quick, curious, conversational"
    case .cancer: return "Gentle, emotionally attuned, symbolic"
    case .leo: return "Expressive, story-driven, creative"
    default: return "In the tone of \(sign.rawValue) communication"
    }
}

func cognitiveFocus(from house: Int) -> String {
    switch house {
    case 3: return "Day-to-day communication and local connections"
    case 4: return "Private emotional memory and family dynamics"
    case 10: return "Reputation, visibility, and public contribution"
    default: return "Focus flows to House \(house)"
    }
}

func symbolicTone(from mercurySign: Zodiac, _ moonSign: Zodiac) -> String {
    return "Metaphors that feel like \(mercurySign.rawValue) logic wrapped in \(moonSign.rawValue) emotion"
}


func relationalValue(from planet: CelestialObject, topAspects: [NatalAspectScore]) -> String {
    switch planet.planet {
    case .venus: return "Deep resonance with beauty, mutual respect, and harmonious connection"
    case .mars: return "Courageous engagement, honesty in conflict, and passion-driven relating"
    case .moon: return "Emotional attunement, safety, and nurturing presence"
    default:
        if topAspects.contains(where: { $0.aspect.kind == .opposition }) {
            return "Polarities that challenge you to grow and integrate with others"
        } else {
            return "Authenticity, mutual growth, and shared purpose"
        }
    }
}
func blossomingConditions(from moonSign: Zodiac, aspects: [NatalAspectScore]) -> String {
    switch moonSign {
    case .cancer:
        return "They blossom when others are attuned to their feelings and offer quiet, steady presence."
    case .aquarius:
        return "They flourish in environments where they are emotionally free, unjudged, and intellectually stimulated."
    case .leo:
        return "They open up when seen and appreciated, especially when joy and play are welcomed."
    case .virgo:
        return "They feel nurtured when their needs are noticed in practical ways, and space is clean and intentional."
    default:
        return "They blossom where their Moon sign's emotional nature is honored with presence and kindness."
    }
}

func perceptionLens(from sign: Zodiac) -> String {
    switch sign {
    case .gemini: return "Through curiosity, dialogue, and layered complexity"
    case .scorpio: return "Through emotional depth, intensity, and uncovering the hidden"
    case .capricorn: return "Through structure, integrity, and practical realism"
    case .pisces: return "Through symbolism, dreams, and emotional intuition"
    default: return "Through the natural style of the dominant sign"
    }
}

func virtueInDevelopment(from planet: CelestialObject, aspects: [NatalAspectScore]) -> String {
    if aspects.contains(where: { $0.aspect.kind == .square }) {
        return "Strength through challenge and persistent effort"
    } else if aspects.contains(where: { $0.aspect.kind == .trine }) {
        return "Grace in flow and natural expression of your gift"
    } else {
        return "Integration of diverse forces into spiritual maturity"
    }
}

// MARK: - RelationalSignature Helpers

func emotionalPace(from planet: CelestialObject, aspects: [NatalAspectScore]) -> String {
    if aspects.contains(where: { $0.aspect.kind == .square || $0.aspect.kind == .opposition }) {
        return "Cautious but intense—emotion builds through pressure"
    } else {
        return "Responsive and open—emotion flows through resonance"
    }
}

func learningStyle(from sign: Zodiac) -> String {
    switch sign {
    case .gemini: return "Curious, fast-moving, and thrives on variety"
    case .taurus: return "Slow, methodical, and needs to feel grounded"
    case .scorpio: return "Deep, penetrating, and driven by hidden meaning"
    default: return "Learns best through the dominant sign’s rhythm and depth"
    }
}

func knownEdges(from profile: UserChartProfile) -> [String] {
    if profile.topAspectsToMoon.contains(where: { $0.aspect.kind == .square }) {
        return ["Emotional vulnerability", "Trusting others with your truth"]
    } else {
        return ["Integrating your emotional world with your public path"]
    }
}

func knownGifts(from profile: UserChartProfile) -> [String] {
    if profile.topAspectsToSun.contains(where: { $0.aspect.kind == .trine }) {
        return ["Natural confidence", "Ability to inspire others"]
    } else {
        return ["Capacity for growth through effort", "Resilient leadership"]
    }
}

// MARK: - AlchemicalToneProfile Helpers

func soulFunction(from planet: CelestialObject) -> String {
    switch planet.planet {
    case .moon: return "To nurture, feel, and reflect emotional truth"
    case .sun: return "To radiate, create, and express core vitality"
    case .saturn: return "To structure, refine, and steward responsibility"
    case .pluto: return "To transform, regenerate, and empower"
    case .mercury: return "To translate, perceive, and communicate meaning"
    default: return "To develop the function symbolized by your strongest planet"
    }
}

func signClimate(from sign: Zodiac) -> String {
    switch sign {
    case .aries: return "Driven, bold, and instinctual"
    case .libra: return "Harmonizing, reflective, and attuned to beauty"
    case .sagittarius: return "Expansive, enthusiastic, and seeking higher truth"
    default: return "Shaped by the qualities of \(sign.rawValue)"
    }
}

func houseArena(from house: Int) -> String {
    switch house {
    case 4: return "Root healing, emotional foundations, and family karma"
    case 7: return "Conscious relationship dynamics and mutual mirroring"
    case 10: return "Purpose, legacy, and contribution to the world"
    default: return "Developmental focus in the realm of House \(house)"
    }
}

func keyForces(from aspects: [NatalAspectScore]) -> [String] {
    return aspects.prefix(2).map { aspectScore in
        let aspectType = aspectScore.aspect.kind.description
        let other = aspectScore.aspect.body2.body.keyName
        return "\(aspectType) with \(other)"
    }
}

func derivedVirtues(from planet: CelestialObject, topAspects: [NatalAspectScore]) -> [String] {
    var virtues: [String] = []
    if topAspects.contains(where: { $0.aspect.kind == .square }) {
        virtues.append("Resilience")
    }
    if topAspects.contains(where: { $0.aspect.kind == .trine }) {
        virtues.append("Grace")
    }
    virtues.append("Discernment") // Always needed
    return virtues
}

func preferredReception(from profile: UserChartProfile) -> String {
    switch profile.mercurySign {
    case .cancer: return "Emotional, reflective, and nurturing tone"
    case .virgo: return "Precise, humble, and practical communication"
    case .aquarius: return "Inventive, pattern-based, and future-focused"
    default: return "In a tone that mirrors their Mercury's element and rhythm"
    }
}

// STEP: Generate UserCoreChartProfile from UserChartProfile

func buildCoreChartProfile(from profile: UserChartProfile) -> UserCoreChartProfile {
    return UserCoreChartProfile(
        strongestPlanet: profile.strongestPlanet,
        strongestPlanetSign: profile.strongestPlanetSign,
        strongestPlanetHouse: profile.strongestPlanetHouse,
        strongestPlanetTopAspect: profile.topAspectsToStrongestPlanet.first,

        strongestSign: profile.dominantSignScores.sorted(by: { $0.value > $1.value }).first?.key ?? profile.strongestPlanetSign,
        strongestHouses: Array(profile.dominantHouseScores.sorted(by: { $0.value > $1.value }).prefix(3).map { $0.key }),

        sunSign: profile.sunSign,
        sunHouse: profile.sunHouse,
        topAspectToSun: profile.topAspectsToSun.first,

        moonSign: profile.moonSign,
        moonHouse: profile.moonHouse,
        topAspectToMoon: profile.topAspectsToMoon.first,

        ascendantSign: profile.ascendantSign,
        topAspectToAscendant: profile.topAspectsToAscendant.first,

        mercurySign: profile.mercurySign,
        mercuryHouse: profile.mercuryHouse,

        topAspectsToStrongestPlanet: profile.topAspectsToStrongestPlanet,
        topAspectsToSun: profile.topAspectsToSun,
        topAspectsToMoon: profile.topAspectsToMoon,
        topAspectsToAscendant: profile.topAspectsToAscendant
    )
}
