//
//  CoT2.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/28/25.
//

import Foundation
import SwiftEphemeris



struct NatalAspectScore {
    let aspect: CelestialAspect
    let score: Double
}



enum ProgressionLayer: String, CaseIterable {
    case major, solarArc, minor, transit
}

struct Activation {
    let source: CelestialObject             // The moving planet
    let target: CelestialObject            // The natal/progressed planet or cusp
    let aspect: Kind
    let orb: Double
    let applying: Bool
    let startDate: Date
    let endDate: Date
    let fromLayer: ProgressionLayer
}


struct AspectAnalysisInput {
    let planetA: CelestialObject
    let planetB: CelestialObject
    let natalHouseA: Int
    let natalHouseB: Int
    let ruledHousesA: [Int]
    let ruledHousesB: [Int]
    let aspectType: Kind
}

struct ProgressedAspectAnalysisInput {
    let planetA: PlanetPlacement
    let planetB: PlanetPlacement
    let aspect: Kind
    let conditioning: [Conditioning]
    let environment: EnvironmentSnapshot
    let supportingAspects: [SupportingProgressedAspect]
    let userProfile: UserChartProfile?
    let layer: ProgressionLayer  // 👈 NEW FIELD
}
struct SynastryUserProfile {
    let name: String
    let birthDate: Date
    let sex: ChartCake.Sex
    let strongestPlanet: CelestialObject
    let sunSign: Zodiac
    let moonSign: Zodiac
    let ascendantSign: Zodiac
    let dominantHouseScores: [Int: Double]
    let dominantSignScores: [Zodiac: Double]
    let dominantPlanetScores: [CelestialObject: Double]
}

struct SynastryContext {
    let userA: SynastryUserProfile
    let userB: SynastryUserProfile
    let interaspects: [Interaspect]
    let compositeProfile: CompositeProfile
    let currentTransitsA: [Activation]
    let currentTransitsB: [Activation]
    let progressionsA: [Activation]
    let progressionsB: [Activation]
}
struct Interaspect {
    let from: CelestialObject
    let to: CelestialObject
    let aspect: Kind
    let score: Double
}

struct CompositeProfile {
    let compositeSunSign: Zodiac
    let compositeMoonSign: Zodiac
    let compositeAscendant: Zodiac
    let strongestCompositePlanet: CelestialObject
    let topCompositeAspects: [NatalAspectScore]
    let dominantCompositeHouses: [Int: Double]
}

struct Conditioning {
    let house: Int
    let frequency: Int  // how often events happened
    let emotionalTone: Float  // positive/negative
}

struct EnvironmentSnapshot {
    let activeHouses: [Int]
    let description: String  // e.g. "Currently preparing a performance tour"
}

struct SupportingProgressedAspect {
    let from: CelestialObject
    let to: CelestialObject
    let aspect: Kind
}
struct PlanetPlacement {
    let planet: CelestialObject
    let natalHouse: Int?         // only set if natal planet
    let currentHouse: Int?       // only set if transit, minor, or major
    let ruledHouses: [Int]       // only for natal planet
    let sign: String
    let isProminent: Bool
}


class CoTPromptGenerator {
    private static func formatNatalAspectList(_ aspects: [NatalAspectScore]) -> String {
        aspects.map { asp in
            let aspect = asp.aspect
            return "  - \(aspect.body1.body.keyName) \(aspect.kind.description) \(aspect.body2.body.keyName) (Score: \(asp.score))"
        }.joined(separator: "\n") + "\n"
    }

    static func generatePrompt(from input: ProgressedAspectAnalysisInput) -> String {
        var prompt = "You are an astrologer analyzing a progressed aspect using a Chain of Thought process.\n\n"

        // MARK: Natal Context
        if let profile = input.userProfile {
            prompt += "**Natal Context – Dominant Function:**\n"
            prompt += "- Strongest Planet: \(profile.strongestPlanet.keyName) in \(profile.strongestPlanetSign.keyName)\n"
            prompt += "- House: \(profile.strongestPlanetHouse), Rules Houses: \(profile.strongestPlanetRuledHouses.map { "\($0)" }.joined(separator: ", "))\n"
            prompt += "- Most Harmonious Planet: \(profile.mostHarmoniousPlanet.keyName)\n"
            prompt += "- Most Discordant Planet: \(profile.mostDiscordantPlanet.keyName)\n"
            prompt += "- Dominant Planet Scores: \(describeTopDominantPlanets(from: profile.dominantPlanetScores))\n\n"

            prompt += "**Secondary Reference Points:**\n"
            prompt += "- Sun: \(profile.sunSign.keyName), House: \(profile.sunHouse), Power: \(profile.sunPower.rounded(toPlaces: 2))\n"
            prompt += "- Moon: \(profile.moonSign.keyName), House: \(profile.moonHouse), Power: \(profile.moonPower.rounded(toPlaces: 2))\n"
            prompt += "- Ascendant: \(profile.ascendantSign.keyName), Power: \(profile.ascendantPower.rounded(toPlaces: 2))\n"
            prompt += "- Ascendant Rulers: \(profile.ascendantRulers.map { $0.keyName }.joined(separator: ", "))\n"
            prompt += "- Ascendant Ruler Signs: \(profile.ascendantRulerSigns.map { $0.keyName }.joined(separator: ", "))\n"
            prompt += "- Ascendant Ruler Houses: \(profile.ascendantRulerHouses.map { "\($0)" }.joined(separator: ", "))\n"
            prompt += "- Ascendant Ruler Powers: \(profile.ascendantRulerPowers.map { "\($0.rounded(toPlaces: 2))" }.joined(separator: ", "))\n\n"

            // MARK: Natal Aspects
            prompt += "**Key Natal Aspects:**\n"
            prompt += "- Top Aspects to Strongest Planet:\n"
            prompt += formatNatalAspectList(profile.topAspectsToStrongestPlanet)

            prompt += "- Top Aspects to Moon:\n"
            prompt += formatNatalAspectList(profile.topAspectsToMoon)

            prompt += "- Top Aspects to Ascendant:\n"
            prompt += formatNatalAspectList(profile.topAspectsToAscendant)

            if !profile.topAspectsToAscendantRulers.isEmpty {
                prompt += "- Top Aspects to Ascendant Rulers:\n"
                prompt += formatNatalAspectList(profile.topAspectsToAscendantRulers)
            }

            prompt += "\n"
        }

        // MARK: Progressed Aspect Type
        let layerLabel: String
        switch input.layer {
        case .major: layerLabel = "Major Progression"
        case .minor: layerLabel = "Minor Progression"
        case .transit: layerLabel = "Transit"
        case .solarArc: layerLabel = "Solar Arc"
        }

        prompt += "**Progressed Aspect:** \(input.planetA.planet.keyName) \(input.aspect.description) \(input.planetB.planet.keyName) (\(layerLabel))\n\n"

        // MARK: Planetary Details
        prompt += "**Planetary Details:**\n"
        for planet in [input.planetA, input.planetB] {
            let ruledHouses = planet.ruledHouses.filter { $0 != planet.natalHouse }
            let ruledText = ruledHouses.isEmpty ? "None" : ruledHouses.map { "\($0)" }.joined(separator: ", ")

            var detail = "- \(planet.planet.keyName): "
            if let natal = planet.natalHouse {
                detail += "Natal House \(natal)"
            }
            if let current = planet.currentHouse {
                if planet.natalHouse != nil {
                    detail += ", Current House \(current)"
                } else {
                    detail += "Current House \(current)"
                }
            }
            detail += ", Rules Houses: \(ruledText), Prominent: \(planet.isProminent ? "Yes" : "No")\n"
            prompt += detail
        }

        // MARK: Conditioning
        if !input.conditioning.isEmpty {
            prompt += "\n**Conditioning:**\n"
            for condition in input.conditioning {
                prompt += "- House \(condition.house): Frequency \(condition.frequency), Tone \(condition.emotionalTone)\n"
            }
        }

        // MARK: Environment
        prompt += "\n**Environment Snapshot:**\n"
        prompt += "Active Houses: \(input.environment.activeHouses.map { "\($0)" }.joined(separator: ", "))\n"
        prompt += "Description: \(input.environment.description)\n"

        // MARK: Supporting Aspects
        if !input.supportingAspects.isEmpty {
            prompt += "\n**Supporting Progressed Aspects (Rallying Forces):**\n"
            for asp in input.supportingAspects {
                prompt += "- \(asp.from.keyName) \(asp.aspect.description) \(asp.to.keyName)\n"
            }
        }

        // MARK: Instructions
        prompt += """

        Please analyze the progressed aspect in 5 steps:

        1. Identify likely planetary effects and house influences.
        2. Eliminate improbable outcomes based on birth chart prominence (especially the strongest planet).
        3. Factor in past conditioning.
        4. Factor in other active aspects (Rallying Forces).
        5. Narrow down probable event(s) based on the current environment.

        End with a summary prediction and a suggestion on how the user can align with the most fortunate version of this event.
        """

        return prompt
    }


    // Helper: Describe top dominant planets
    private static func describeTopDominantPlanets(from scores: [CelestialObject: Double]) -> String {
        let sorted = scores.sorted { $0.value > $1.value }.prefix(3)
        return sorted.map { "\($0.key.keyName): \($0.value.rounded(toPlaces: 2))" }.joined(separator: ", ")
    }
}

// Add this helper
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
class OpenAIService {
    private let apiKey: String
    private let model = "gpt-4o"  // You can also use "gpt-3.5-turbo"

    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendConversation(messages: [[String: String]], completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    // 👇 PRINT RAW JSON + CONTENT
                    print("🧠 [OpenAI raw response]:\n\(json)")
                    print("💬 [Model reply]:\n\(content)\n")

                    completion(content)
                } else {
                    print("❌ [OpenAI] Unexpected JSON format")
                    completion(nil)
                }
            } catch {
                print("❌ [OpenAI] JSON parsing error: \(error)")
                completion(nil)
            }
        }.resume()
    }

    func sendPrompt(_ prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a wise, grounded astrologer who uses a logical, structured chain-of-thought method to analyze progressed aspects."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        print("🧠 [OpenAI Prompt]: \(prompt)")
        

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("💬 [OpenAI Completion content]: \(content)")
                    print("💬 [OpenAI Completion message]: \(message)")
                    print("💬 [OpenAI Completion choices]: \(choices)")
                    completion(content)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
//  QueryHouseResolver.swift
//  Ask Lila

import Foundation

struct QueryResolutionResult {
    let needsClarification: Bool
    let likelyHouses: [Int]
    let followUpQuestion: String?
}

class HouseResolverService {
    private let openAI: OpenAIService

    init(openAIService: OpenAIService) {
        self.openAI = openAIService
    }

    func resolveQuery(_ userQuery: String, fallback: Bool = true, completion: @escaping (QueryResolutionResult) -> Void) {
        // Step 1: Try using LLM for deeper understanding
        let systemPrompt = """
        You are a gentle, intuitive astrologer who maps life questions to the relevant astrological houses. 
        Given a user's question, return a JSON object with:
        - likelyHouses: an array of 1–3 house numbers
        - followUpQuestion: a single clarifying question if the user’s query is vague
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userQuery]
        ]

        openAI.sendConversation(messages: messages) { response in
            guard let response = response,
                  let data = response.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let houseArray = json["likelyHouses"] as? [Int] else {
                // Step 2: Fallback to keyword matching if parsing fails
                if fallback {
                    completion(self.keywordFallback(for: userQuery))
                } else {
                    completion(QueryResolutionResult(needsClarification: false, likelyHouses: [], followUpQuestion: nil))
                }
                return
            }

            let followUp = json["followUpQuestion"] as? String
            completion(QueryResolutionResult(needsClarification: followUp != nil, likelyHouses: houseArray, followUpQuestion: followUp))
        }
    }

    private func keywordFallback(for query: String) -> QueryResolutionResult {
        let lowercased = query.lowercased()

        if lowercased.contains("relationship") || lowercased.contains("partner") || lowercased.contains("marriage") {
            return .init(needsClarification: false, likelyHouses: [7], followUpQuestion: nil)
        } else if lowercased.contains("career") || lowercased.contains("job") || lowercased.contains("work") {
            return .init(needsClarification: false, likelyHouses: [10], followUpQuestion: nil)
        } else if lowercased.contains("money") || lowercased.contains("finances") || lowercased.contains("income") || lowercased.contains("resources") {
            return .init(needsClarification: false, likelyHouses: [2], followUpQuestion: nil)
        } else if lowercased.contains("family") || lowercased.contains("home") || lowercased.contains("roots") {
            return .init(needsClarification: false, likelyHouses: [4], followUpQuestion: nil)
        } else if lowercased.contains("health") || lowercased.contains("body") || lowercased.contains("energy") {
            return .init(needsClarification: false, likelyHouses: [6, 1], followUpQuestion: nil)
        } else if lowercased.contains("friends") || lowercased.contains("community") || lowercased.contains("social") {
            return .init(needsClarification: false, likelyHouses: [11], followUpQuestion: nil)
        } else if lowercased.contains("purpose") || lowercased.contains("life path") || lowercased.contains("direction") || lowercased.contains("spiritual") {
            return .init(needsClarification: false, likelyHouses: [9, 10], followUpQuestion: nil)
        } else if lowercased.contains("intimacy") || lowercased.contains("trauma") || lowercased.contains("healing") {
            return .init(needsClarification: false, likelyHouses: [8], followUpQuestion: nil)
        } else {
            return .init(
                needsClarification: true,
                likelyHouses: [],
                followUpQuestion: "Is this more about your relationships, your work, your inner world, or something else?"
            )
        }
    }
}

class SynastryPromptGenerator {
    static func generatePrompt(from context: SynastryContext) -> String {
        var prompt = "You are a wise friend who hapens to me a master of evolutionary astrology who specializes in relationship compatibility and soul growth through synastry and composite charts. your favoorite quote about synastry from your teacher Steven Forrest is: The gift astrology offers is simply one of clear seeing. It serves as a wise third party, mirroring each lover’s viewpoint, needs, and nature with neutrality and evolutionary insight. Used sensitively, it does not pontificate and judge. That’s not how conscious, evolutionary astrology operates. Instead, it seeks only to promote mutual understanding.\n\n"

        // 🔹 Brief bios
        // User A
        prompt += "**User A** – \(context.userA.name)\n"
        prompt += "- Strongest Planet: \(context.userA.strongestPlanet.keyName)\n"
        prompt += "- Sun: \(context.userA.sunSign.keyName)\n"
        prompt += "- Moon: \(context.userA.moonSign.keyName)\n"
        prompt += "- Ascendant: \(context.userA.ascendantSign.keyName)\n"
        prompt += "- Strongest Sign: \(context.userA.dominantSignScores.max { $0.value < $1.value }?.key.keyName ?? "Unknown")\n"
        prompt += "- Strongest House: \(context.userA.dominantHouseScores.max { $0.value < $1.value }?.key ?? -1)\n"
        prompt += "- Top 3 Signs: \(topZodiacs(from: context.userA.dominantSignScores))\n"
        prompt += "- Top 3 Houses: \(topHouses(from: context.userA.dominantHouseScores))\n\n"

        // User B
        prompt += "**User B** – \(context.userB.name)\n"
        prompt += "- Strongest Planet: \(context.userB.strongestPlanet.keyName)\n"
        prompt += "- Sun: \(context.userB.sunSign.keyName)\n"
        prompt += "- Moon: \(context.userB.moonSign.keyName)\n"
        prompt += "- Ascendant: \(context.userB.ascendantSign.keyName)\n"
        prompt += "- Strongest Sign: \(context.userB.dominantSignScores.max { $0.value < $1.value }?.key.keyName ?? "Unknown")\n"
        prompt += "- Strongest House: \(context.userB.dominantHouseScores.max { $0.value < $1.value }?.key ?? -1)\n"
        prompt += "- Top 3 Signs: \(topZodiacs(from: context.userB.dominantSignScores))\n"
        prompt += "- Top 3 Houses: \(topHouses(from: context.userB.dominantHouseScores))\n\n"

        // 🔹 Interaspects
        prompt += "**Key Interaspects (User A → User B):**\n"
        for inter in context.interaspects.sorted(by: { $0.score > $1.score }).prefix(10) {
            prompt += "- \(inter.from.keyName) \(inter.aspect.description) \(inter.to.keyName) Score: \(inter.score.rounded(toPlaces: 2)))\n"
        }

        // 🔹 Composite
        prompt += "\n**Composite Chart:**\n"
        prompt += "- Sun: \(context.compositeProfile.compositeSunSign.keyName)\n"
        prompt += "- Moon: \(context.compositeProfile.compositeMoonSign.keyName)\n"
        prompt += "- Ascendant: \(context.compositeProfile.compositeAscendant.keyName)\n"
        prompt += "- Strongest Planet: \(context.compositeProfile.strongestCompositePlanet.keyName)\n"
        prompt += "- Dominant Houses: \(context.compositeProfile.dominantCompositeHouses.sorted { $0.value > $1.value }.prefix(3).map { "House \($0.key): \($0.value.rounded(toPlaces: 2))" }.joined(separator: ", "))\n"

        prompt += "- Top Aspects:\n"
        for asp in context.compositeProfile.topCompositeAspects {
            prompt += "  • \(asp.aspect.body1.body.keyName) \(asp.aspect.kind.description) \(asp.aspect.body2.body.keyName) (Score: \(asp.score.rounded(toPlaces: 2)))\n"
            
            
            prompt += """
            **Chain of Thought Relationship Analysis**

            Please interpret this connection using a 3-layered synthesis:

            1. **Natal Resonance**  
               Begin by comparing the dominant features of each person’s chart — especially their strongest planet, dominant sign and house, Sun, Moon, and Ascendant.  
               - What innate psychological patterns and needs are each person bringing into the relationship?
               - Where is there natural alignment or shared frequency?
               - Where might tension arise, and what evolutionary potential lies within it?

            2. **Interaspect Chemistry**  
               Layer in the key interaspects to explore how these two psyches interact.  
               - What archetypal conversations are happening between them?
               - Which planets are forming the most impactful bonds or frictions?
               - How do these dynamics support or challenge their growth?

            3. **Composite Chart + Current Activations**  
               Now synthesize both natal and interaspect data into the shared purpose of the relationship as revealed in the composite chart.  
               - What is this relationship here to teach or unlock in each person?
               - How are current transits and progressions activating this shared path right now?

            🧭 **Final Synthesis**  
            Draw all three layers together into a cohesive insight:
            - What is the deeper story unfolding between these two?
            - How can each person consciously participate in the growth this relationship invites?
            - What timing considerations (based on current activations) might help them align with the highest version of this connection?

            Speak with wisdom, clarity, and compassion — your goal is to reveal the soul contract between them.
            """

        }

        // 🔹 Current Energies
        func formatActivations(_ acts: [Activation], title: String) -> String {
            let grouped = Dictionary(grouping: acts, by: \.fromLayer)
            var result = "**\(title):**\n"
            for layer in ProgressionLayer.allCases {
                if let group = grouped[layer], !group.isEmpty {
                    result += "- \(layer.rawValue.capitalized):\n"
                    for act in group.prefix(3) {
                        result += "  • \(act.source.keyName) \(act.aspect.description) \(act.target.keyName) (Orb: \(act.orb), Applying: \(act.applying))\n"
                    }
                }
            }
            return result + "\n"
        }

        prompt += "\n" + formatActivations(context.currentTransitsA + context.progressionsA, title: "User A's Current Activations")
        prompt += "\n" + formatActivations(context.currentTransitsB + context.progressionsB, title: "User B's Current Activations")

        // 🔚 Instructions
        prompt += """
        Now, analyze the current state of their relationship and suggest how each person can grow through it. Focus on key tensions, supportive patterns, and psychological insights from both the synastry and composite charts. Be specific and compassionate.
        """

        return prompt
    }
    private static func topZodiacs(from scores: [Zodiac: Double], count: Int = 3) -> String {
           scores.sorted { $0.value > $1.value }
               .prefix(count)
               .map { "\($0.key.keyName): \($0.value.rounded(toPlaces: 2))" }
               .joined(separator: ", ")
       }

       private static func topHouses(from scores: [Int: Double], count: Int = 3) -> String {
           scores.sorted { $0.value > $1.value }
               .prefix(count)
               .map { "House \($0.key): \($0.value.rounded(toPlaces: 2))" }
               .joined(separator: ", ")
       }
}

class SynastryBuilder {
    
   
    // Generate interaspects between person A and B
    static func generateInteraspects(from synastryChart: SynastryChart) -> [Interaspect] {
        let coordsA = synastryChart.chart1.planets
        let coordsB = synastryChart.chart2.planets
        let name1 = synastryChart.name1
        let name2 = synastryChart.name2

        let rawAspects = synastryChart.interAspects(
            rickysPlanets: coordsA,
            linneasPlanets: coordsB,
            name1: name1,
            name2: name2
        )

        let scoredAspects = synastryChart.interchartAspectScores(aspects: rawAspects, name1: name1, name2: name2)

        return scoredAspects.map { (aspect, score) in
            Interaspect(
                from: aspect.body1.body,
                to: aspect.body2.body,
                aspect: aspect.kind,
                score: score
            )
        }
    }


    // Composite chart from midpoint method (simplified version)
    static func generateCompositeProfile(from synastryChart: SynastryChart) -> CompositeProfile {
        let compositeChart = Chart(alpha: synastryChart.chart1, bravo: synastryChart.chart2)

        let coordinates = compositeChart.rickysBodies

        // Planet power
        let planetPowerScores = compositeChart.getTotalPowerScoresForPlanetsCo(coordinates)

        // Grab the coordinate with the highest score
        let strongestPlanetCoord = planetPowerScores.max { $0.value < $1.value }?.key

        // Get the CelestialObject from the coordinate
        let strongestPlanet = strongestPlanetCoord?.body ?? synastryChart.chart1.sun.body  // fallback if nil


        // Sign strength
        let signScores = compositeChart.calculateTotalSignScore(coordinates)
        let dominantSign = signScores.max { $0.value < $1.value }?.key ?? .aries

        // House dominance
        let dominantHouses = compositeChart.calculateHouseStrengths(coordinates)

        // Aspects
        let aspectsScores = compositeChart.allCelestialAspectScoresByAspect()
        let topAspects = compositeChart.planets
            .flatMap { planet in
                compositeChart.filterAndFormatNatalAspects(by: planet.body, aspectsScores: aspectsScores)
            }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { NatalAspectScore(aspect: $0.key, score: $0.value) }

        return CompositeProfile(
            compositeSunSign: compositeChart.sun.sign,
            compositeMoonSign: compositeChart.moon.sign,
            compositeAscendant: compositeChart.ascendantCoordinate.sign,
            strongestCompositePlanet: strongestPlanet,
            topCompositeAspects: topAspects,
            dominantCompositeHouses: dominantHouses
        )
    }

    // Pull all current activations for a person
    static func currentActivations(for cake: ChartCake) -> [Activation] {
        let natalPlanets = cake.natal.planets.map { $0.body }
        var activations: [Activation] = []

        for target in natalPlanets {
            let layers: [(ProgressionLayer, [CelestialAspect])] = [
                (.major, cake.progressedSimpleAspectsFiltered(by: target)),
                (.solarArc, cake.solarArcSimpleAspectsFiltered(by: target)),
                (.minor, cake.minorProgressedSimpleAspectsFiltered(by: target)),
                (.transit, cake.transitSimpleAspectsFiltered(by: target))
            ]

            for (layer, aspects) in layers {
                for asp in aspects {
                    activations.append(Activation(
                        source: asp.body1.body,
                        target: asp.body2.body,
                        aspect: asp.kind,
                        orb: asp.orb,
                        applying: asp.type == .applying,
                        startDate: asp.startDate,
                        endDate: asp.endDate,
                        fromLayer: layer
                    ))
                }
            }
        }

        return activations
    }
}
struct NatalPromptGenerator {
    static func generatePrompt(from profile: MyUserChartProfile) -> String {
        var prompt = "You are a wise, friend who is a master of evolutionary astrology. Who, unlike most convential astrologers knows the most powerful thing in a chart is the strongest planet. You know your job is to help your friend see themeslevs more clearly. Youre favorite lines from your mentor and Teacher Steven Forrest are: the real purpose of astrology: to hold a mirror before the evolving self, to tell us what we already know deep within ourselves. Through astrology we fly far above the mass of details that constitutes our lives. We stand outside our personalities and see for a moment the central core of individuality around which all the minutiae must always orbit. This is how you assist your friend  \(profile.name ?? "User").\n\n"
        
        prompt += "**Name**: \(profile.name ?? "User")\n"
        prompt += "- Strongest Planet: \(profile.strongestPlanet.keyName) in \(profile.strongestPlanetSign.keyName), House \(profile.strongestPlanetHouse) and ruling the cuso of House(s) \(profile.strongestPlanetRuledHouses.sorted().map(String.init).joined(separator: ", "))\n"
        prompt += "- Sun: \(profile.sunSign.keyName) in House \(profile.sunHouse)\n"
        prompt += "- Moon: \(profile.moonSign.keyName) in House \(profile.moonHouse)\n"
        prompt += "- Ascendant: \(profile.ascendantSign.keyName)\n"
        prompt += "- Most Harmonious Planet: \(profile.mostHarmoniousPlanet.keyName)\n"
        prompt += "- Most Discordant Planet: \(profile.mostDiscordantPlanet.keyName)\n\n"
        
        prompt += "**Dominant Signs**:\n"
        for (sign, score) in profile.dominantSignScores.sorted(by: { $0.value > $1.value }).prefix(3) {
            prompt += "- \(sign.keyName): \(String(format: "%.2f", score))\n"
        }

        prompt += "\n**Dominant Houses**:\n"
        for (house, score) in profile.dominantHouseScores.sorted(by: { $0.value > $1.value }).prefix(3) {
            prompt += "- House \(house): \(String(format: "%.2f", score))\n"
        }

        prompt += "\nNow analyze this chart. What stands out? What are some key themes in their personality and life path?"

        return prompt
    }
}
