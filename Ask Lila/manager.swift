//
//  manager.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/29/25.
//

import Foundation
//
//  LilaMemoryManager.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.

import Foundation
import SwiftEphemeris
import UIKit
import CoreData

import Foundation
import CoreData

struct AIResponse: Codable {
    let reply: String
}

class LilaMemoryManager {
    static let shared = LilaMemoryManager()

    private var internalPrompts: [String] = []

    // MARK: - Message Storage
    func saveMessage(role: String, content: String, date: Date = Date()) {
        // Save to Core Data
        let context = CoreDataManager.shared.context
        let message = ConversationMemory(context: context)
        message.id = UUID()
        message.role = role
        message.content = content
        message.timestamp = date
        
        do {
            try context.save()
            print("✅ Saved \(role) message to Core Data")
        } catch {
            print("❌ Error saving message to Core Data: \(error.localizedDescription)")
        }
        
        // Also log to Firestore if this is completing a conversation pair
        if role == "assistant" {
            // Get recent messages (limit to 20 for performance)
            let fetchRequest: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchLimit = 20
            
            do {
                let recentMessages = try context.fetch(fetchRequest)
                // Sort chronologically for processing
                let sortedMessages = recentMessages.sorted(by: { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) })
                
                // Find the most recent user message
                if let lastUserMessage = sortedMessages.last(where: { $0.role == "user" }),
                   let userContent = lastUserMessage.content {
                    
                    // Log the conversation pair to Firestore
                    ConversationLogger.shared.logConversation(
                        prompt: userContent,
                        response: content,
                        readingType: determineReadingType(),
                        chartName: getCurrentChartName()
                    )
                    
                    print("✅ Logged conversation pair to Firestore")
                }
            } catch {
                print("❌ Error fetching recent messages: \(error.localizedDescription)")
            }
        }
    }

    // Helper methods to get context for FireStore
 func determineReadingType() -> String {
        // First try to get from active chart context if available
        if let chartCake = UserDefaults.standard.string(forKey: "currentChartType") {
            if chartCake.contains("synastry") || chartCake.contains("relationship") {
                return "SYNASTRY/RELATIONSHIP"
            } else if chartCake.contains("transit") || chartCake.contains("progression") {
                return "TRANSIT & PROGRESSION"
            }
        }
        
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: "currentReadingType") ?? "NATAL CHART"
    }

    private func getCurrentChartName() -> String {
        return UserDefaults.standard.string(forKey: "currentChartName") ?? "Unknown"
    }
    
    func debugPrintRecentMessages(count: Int = 5) {
        let messages = fetchConversationHistory()
        print("--- DEBUG: Last \(count) messages ---")
        for (index, message) in messages.suffix(count).enumerated() {
            print("[\(index)] \(message.role ?? "unknown"): \(message.content?.prefix(50) ?? "no content")...")
        }
        print("--------------------------------")
    }
    func fetchConversationHistory(for date: Date? = nil, topic: String? = nil) -> [ConversationMemory] {
        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        var predicates: [NSPredicate] = []

        if let date = date {
            let startOfDay = date.adjust(for: .startOfDay)!
            let endOfDay = date.adjust(for: .endOfDay)!
            predicates.append(NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as CVarArg, endOfDay as CVarArg))
        }

        if let topic = topic {
            predicates.append(NSPredicate(format: "content CONTAINS[cd] %@", topic))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            return try CoreDataManager.shared.context.fetch(request)
        } catch {
            print("❌ Error fetching memory: \(error)")
            return []
        }
    }

    func clearConversationHistory() {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ConversationMemory")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ Successfully cleared conversation history!")
        } catch {
            print("❌ Error clearing conversation history: \(error)")
        }
    }

    // MARK: - Internal Prompts (Hidden from UI)

    func addInternalPrompt(_ prompt: String) {
        internalPrompts.append(prompt)
    }

    func getInternalPrompts() -> String {
        return internalPrompts.joined(separator: "\n\n")
    }

    func clearInternalPrompts() {
        internalPrompts.removeAll()
    }
}

//
//  LilaCoreDataManager.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.

import Foundation
import SwiftEphemeris
import UIKit
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    // Make this private but not with an accessor
    private let _persistentContainer: NSPersistentContainer

    // Public accessor for the persistent container
    var persistentContainer: NSPersistentContainer {
        return _persistentContainer
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            block(context)
        }
    }

    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save background context: \(error)")
            }
        }
    }

    private init() {
        _persistentContainer = NSPersistentContainer(name: "Ask_Lila")

        // ✅ Ensure migration and persistent history tracking are explicitly set
        if let storeDescription = _persistentContainer.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        _persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Persistent Store Error: \(error), \(error.userInfo)")
                self.handleMigrationError()
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save Core Data: \(error)")
            }
        }
    }

    private func handleMigrationError() {
        let storeURL = _persistentContainer.persistentStoreDescriptions.first?.url
        if let storeURL = storeURL {
            do {
                try FileManager.default.removeItem(at: storeURL)
                print("✅ Deleted corrupted store. Restart the app.")
            } catch {
                print("❌ Failed to delete corrupted store: \(error)")
            }
        }
    }
}


//
//  LilaAgentManager.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.

import Foundation
import SwiftEphemeris
import UIKit
import CoreData
import FirebaseFirestore
import FirebaseAuth

class LilaAgentManager {
    // Singleton instance
    static let shared = LilaAgentManager()

        func sendSoulGuidedMessage(prompt: String, completion: @escaping (String?) -> Void) {
            let url = URL(string: "https://your-llm-server/api/v1/ask-lila")! // Adjust accordingly
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let payload = [
                "prompt": prompt,
                "temperature": 0.7,
                "max_tokens": 600
            ] as [String : Any]

            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data, let response = try? JSONDecoder().decode(AIResponse.self, from: data) {
                    completion(response.reply)
                } else {
                    print("❌ AI Error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }.resume()
        }
    

    
    
    private func logConversationToFirestore(userPrompt: String, aiResponse: String, readingType: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let conversationId = UUID().uuidString
        let timestamp = Timestamp(date: Date())

        let conversationRef = db.collection("users")
            .document(userId)
            .collection("conversations")
            .document(conversationId)

        let baseInfo: [String: Any] = [
            "readingType": readingType,
            "startedAt": timestamp
        ]

        let userMessage: [String: Any] = [
            "text": userPrompt,
            "isUser": true,
            "timestamp": timestamp
        ]

        let aiMessage: [String: Any] = [
            "text": aiResponse,
            "isUser": false,
            "timestamp": timestamp
        ]

        conversationRef.setData(baseInfo)
        conversationRef.collection("messages").addDocument(data: userMessage)
        conversationRef.collection("messages").addDocument(data: aiMessage)

        print("✅ Conversation logged for user \(userId)")
    }

    // References to astrology knowledge data - maintained from original implementation
    let teacherAndTricksterDefinitions: String = """
    Pluto: Transformation & Power
    - **Teacher:** The ability to heal one's soul, recovering the energy needed to find an altruistic mission in life, thereby filling one's consciousness with a sense of ultimate purpose.
    - **Trickster:** The temptation to allow rigidity, dogmatism, and power-tripping to narrow our perspective, isolating our egos in a spirit of cynicism, despair, and nihilism. The compulsion to reenact whatever dramas have wounded us in the past.
    
    Neptune: Surrender & Vision
    - **Teacher:** The ability to experience serenity, inspiration, and transcendence in the face of life's dramas; the ability to receive a Vision.
    - **Trickster:** The temptation to deceive or undo ourselves with glamorous falsehoods and easy, self-destructive patterns of escape.
    
    Uranus: Freedom & Authenticity
    - **Teacher:** The ability to distinguish our true individuality from the desires and fantasies about us held by our family, friends, and associates.
    - **Trickster:** The temptation to submit to the herd instinct because it is practical to do so, because the rewards are high, and because the alternatives seem impossible.
    
    Saturn: Mastery & Discipline
    - **Teacher:** The ability to see reality clearly and to respond to it effectively and decisively.
    - **Trickster:** The temptation to slip into despair and frustration when reality seems to turn against us.
    
    Jupiter: Growth & Expansion
    - **Teacher:** The ability both to envision and to seize upon new possibilities and potentials for the future.
    - **Trickster:** The temptation to be lulled into lassitude and foolishness while basking in the warm feelings created by mere glitz, overconfidence, arrogance, or still-incomplete success.
    
    Mars: Courage & Action
    - **Teacher:** The immediate, intentional use of will in a courageous way; the effort to survive as a physical, psychological, and spiritual entity; the right tactical use of assertiveness and aggression.
    - **Trickster:** Freezing in fear or directing aggression at the wrong targets, leading to either self-destruction or pointless conflicts.
    
    Venus: Values & Harmony
    - **Teacher:** The ability to recognize moments for rest and renewal, the discernment to form meaningful alliances, and the capacity to receive support.
    - **Trickster:** Being lulled into complacency, using charm or flattery manipulatively, or indulging in self-destructive pleasures instead of true rejuvenation.
    
    Mercury: Perception & Communication
    - **Teacher:** The capacity for clear thinking, curiosity, and adaptability; the ability to acquire new information and communicate effectively.
    - **Trickster:** Mental restlessness, overanalyzing, nervous chatter, or resisting necessary new information.
    
    Sun: Identity & Purpose
    - **Teacher:** The opportunity for self-awareness, clarity, and direct confrontation with the world.
    - **Trickster:** Stubborn pride, selfishness, or clinging to old identity structures instead of evolving.
    
    Moon: Emotional Awareness
    - **Teacher:** The ability to integrate emotions into conscious awareness, allowing for greater self-understanding and emotional balance.
    - **Trickster:** Emotional reactivity, mood swings, or allowing unprocessed emotions to distort reality.
    """

    // Maintained from original implementation
    let planetaryAttributes: [String: [String: Any]] = [
        "Sun": [
            "Urge": "Power or Significance",
            "Function": [
                "The development of a coherent, operational self-image",
                "The focusing of one's willpower and capacity for positive action",
                "The creation of ego"
            ],
            "Dysfunction": [
                "Selfishness", "insensitivity", "tyranny over the lives of others",
                "vanity", "pomposity", "inflexibility", "imperiousness"
            ],
            "Key Questions": [
                "Who am I?",
                "What kinds of experiences help me strengthen and clarify my self-image? Where can I find and expand my personal power?",
                "What unconscious biases shape my view of the world?"
            ]
        ],
        // Other planets would be included here as in the original code
    ]

    // Maintained from original implementation
    let houseAttributes: [String: [String: Any]] = [
        "First House": [
            "Traditional Name": "House of Personality",
            "Terrain": ["The establishment of personal identity"],
            "Successfully Navigated": [
                "Clarity and decisiveness in one's actions",
                "A sense of control over one's direction in life",
                "A sharply focused sense of identity"
            ],
            "Unsuccessfully Navigated": [
                "Fearfulness and lack of self-assurance leading either to inflexibility and tyranny over the wills of others or to self-effacement, vagueness of purpose, and the assumption of defeat"
            ]
        ],
        // Other houses would be included here as in the original code
    ]

    // Maintained from original implementation
    var giftGiverAndThief: String = """
    Synastry: The Gift Giver & The Thief
    The Sun: Solarization ☀️
    Gift Giver: Brings energy, confidence, and visibility to the other person's planet, inspiring them to express themselves more fully. Encourages growth and authenticity.
    Thief: Overwhelms, eclipses, or dominates the other person's planet, making them feel small or controlled by the solarizing influence.
    The Moon: Lunarization 🌙
    Gift Giver: Creates deep emotional understanding and nurturance, fostering intimacy and a sense of home. Helps the other person feel seen and comforted.
    Thief: Heightens emotional dependency, mood swings, and irrational reactions. The Moon person can smother, unsettle, or infantilize the other person's planet.
    Mercury: Mercurialization 🗣
    Gift Giver: Stimulates intellectual connection, communication, and curiosity. Encourages fresh perspectives and mutual learning.
    Thief: Overanalyzes, confuses, or overwhelms with words. Can make the other person doubt their own thoughts or struggle to articulate themselves clearly.
    Venus: Venusification 💕
    Gift Giver: Creates harmony, attraction, and appreciation. Encourages mutual pleasure, support, and artistic or romantic connection.
    Thief: Seduces without sincerity, manipulates through charm, or creates unrealistic expectations that lead to disillusionment.
    Mars: Martialization 🔥
    Gift Giver: Sparks passion, motivation, and assertiveness. Encourages the other person's planet to take action, express desire, or stand their ground.
    Thief: Provokes conflict, aggression, or power struggles. Can push the other person's planet into defensiveness, exhaustion, or frustration.
    Jupiter: Jovialization 🎉
    Gift Giver: Expands possibilities, encourages optimism, and brings joy. The other person's planet feels more confident and inspired.
    Thief: Promotes overindulgence, arrogance, or reckless optimism. The other person's planet may become ungrounded or overestimate its capabilities.
    Saturn: Saturnization 🏛
    Gift Giver: Provides stability, discipline, and structure. Encourages responsibility and long-term commitment.
    Thief: Feels restrictive, critical, or judgmental. The other person's planet may feel suppressed, unworthy, or overly burdened.
    Uranus: Uranization ⚡
    Gift Giver: Awakens originality, authenticity, and excitement. Encourages freedom and innovation.
    Thief: Creates chaos, instability, or detachment. Can make the other person's planet feel ungrounded, anxious, or disconnected.
    Neptune: Neptunification 🌊
    Gift Giver: Enhances spiritual connection, creativity, and compassion. Fosters inspiration and unconditional love.
    Thief: Creates illusions, deception, or confusion. Can make the other person's planet feel lost in fantasy or emotionally drained.
    Pluto: Plutonification 🔥
    Gift Giver: Intensifies depth, transformation, and empowerment. Encourages profound self-awareness and growth.
    Thief: Manipulates, controls, or emotionally consumes. Can lead to power struggles, obsessive dynamics, or destructive patterns.
    """
    
    func calculateAgeString(from birthDate: Date, to selectedDate: Date) -> String {
        let calendar = Calendar.current
        
        // Calculate the difference in years
        let years = calendar.dateComponents([.year], from: birthDate, to: selectedDate).year!
        
        // Calculate the birthday for the current year or the last year
        // depending on whether the selectedDate has passed this year's birthday
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: selectedDate), of: birthDate)!
        let lastBirthday = birthdayThisYear <= selectedDate ? birthdayThisYear : calendar.date(byAdding: .year, value: -1, to: birthdayThisYear)!
        
        // Calculate the difference in days
        let days = calendar.dateComponents([.day], from: lastBirthday, to: selectedDate).day!
        
        // Return the age string
        return "\(years) years and \(days) days"
    }
    // Helper: Describe top dominant planets
     func describeTopDominantPlanets(from scores: [CelestialObject: Double]) -> String {
        let sorted = scores.sorted { $0.value > $1.value }.prefix(3)
        return sorted.map { "\($0.key.keyName): \($0.value.rounded(toPlaces: 2))" }.joined(separator: ", ")
    }


 func formatNatalAspectList(_ aspects: [NatalAspectScore]) -> String {
    aspects.map { asp in
        let aspect = asp.aspect
        return "  - \(aspect.body1.body.keyName) \(aspect.kind.description) \(aspect.body2.body.keyName) (Score: \(asp.score))"
    }.joined(separator: "\n") + "\n"
}

    func generatePrompt(from input: ProgressedAspectAnalysisInput) -> String {
       var prompt = "You are an astrologer analyzing a progressed aspect using a Chain of Thought process.\n\n"

       // Natal Context
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

       return prompt
   }
    
    func sendMessageToAgent(
        prompt: String,
        userChart: ChartCake?,
        otherChart: ChartCake? = nil,
        completion: @escaping (String?) -> Void
    ) {
        guard let userChart = userChart else {
            completion("I need your birth chart data to provide a proper astrological reading.")
            return
        }

        let userName = userChart.name ?? "User"

        // 🔍 Determine reading type
        let readingType: ReadingType = otherChart != nil
            ? .synastry
            : userChart.transits.transitDate != nil ? .transits : .natal

        print("🔍 Performing \(readingType.rawValue) reading for \(userName)")

        // 🧠 System Instructions
//        let systemInstructions = getSystemInstructions(
//            chartCake: userChart,
//            otherChart: otherChart,
//            transitDate: userChart.transits.transitDate
//        )

        // ✅ Use instance of AgentPromptBuilder
        let promptBuilder = AgentPromptBuilder()
        promptBuilder.cake = userChart

        let upgradedContext = promptBuilder.buildContext(
            for: readingType,
            userChart: userChart,
            partnerChart: otherChart
        )

        let fullPrompt = """


        USER QUESTION: \(prompt)

        \(upgradedContext)
        """
  //      print("🧠 SYSTEM INSTRUCTIONS:\n\(systemInstructions)\n")
        print("🗨️ USER QUESTION:\n\(prompt)\n")
        print("📦 UPGRADED CONTEXT:\n\(upgradedContext)\n")
        print("🧾 FULL PROMPT TO MODEL:\n\(fullPrompt)\n")
        // 🎯 Send to current AI service
        let currentService = AIServiceManager.shared.currentService

        currentService.generateResponse(
            prompt: fullPrompt,
            chartCake: userChart,
            otherChart: otherChart,
            transitDate: userChart.transits.transitDate
        ) { result in
            switch result {
            case .success(let response):
                DispatchQueue.global(qos: .background).async {
                    LilaMemoryManager.shared.saveMessage(role: "assistant", content: response)
                }

                completion(response)

                ConversationLogger.shared.logConversation(
                    prompt: prompt,
                    response: response,
                    readingType: readingType.rawValue,
                    chartName: userChart.name,
                    partnerName: otherChart?.name,
                    transitDate: userChart.transits.transitDate
                )

            case .failure(let error):
                print("❌ ERROR: AI service error - \(error.localizedDescription)")
                completion("I'm sorry, but I encountered an issue while analyzing your chart. Please try again.")
            }
        }
    }
    func toneAdjustedResponse(
        userInput: String,
        core: UserCoreChartProfile,
        soul: SoulValuesProfile,
        tone: AlchemicalToneProfile
    ) -> String {
        return """
    🜁 You are a soul-reflective assistant aligned with the 7-Lesson Personal Alchemy philosophy.

    Speak from presence. See the user not as a fixed type, but as a soul in refinement.

    --- CHART TRUTH FILTER ---

    • 🜂 Strongest Planet: \(core.strongestPlanet.keyName) in \(core.strongestPlanetSign.rawValue), House \(core.strongestPlanetHouse)
       → Support refinement of: \(tone.soulFunction)

    • 🌙 Moon: \(core.moonSign.rawValue), House \(core.moonHouse)
       → Nurture in a way that: \(soul.blossomingConditions)

    • ☿ Mercury: \(core.mercurySign.rawValue), House \(core.mercuryHouse)
       → Speak in a tone that honors: \(soul.communicationMode)

    • ☉ Sun: \(core.sunSign.rawValue), House \(core.sunHouse)
       → Encourage radiance by: \(soul.radiancePath)

    • 🏠 Life Arena: \(tone.developmentArena)
    • 🎭 Emotional Climate: \(tone.preferredReception)
    • 🧠 Metaphoric Style: \(tone.symbolicVoiceTone ?? "natural language rooted in personal metaphor")

    --- PHILOSOPHICAL GUIDEPOSTS ---

    This soul is not broken—they are becoming.  
    Every event is an initiatory moment. Every tension is a refinement chamber.  
    Respond with warmth, alchemical curiosity, and a reverent tone.  
    Never diagnose. Always mirror truth through the lens of loving evolution.

    --- USER INPUT ---
    \(userInput)

    --- YOUR RESPONSE (soul-aligned, chart-aware) ---
    """
    }


    // MARK: - New Implementati

    // Helper property for date formatting
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    /**

     */
    private func getSystemInstructions(chartCake: ChartCake?, otherChart: ChartCake?, transitDate: Date?) -> String {
        var systemInstructions = ""
        var personsGender = chartCake?.sex.rawValue
        var otherPersonsGender = otherChart?.sex.rawValue

        // Get names for identity context
        let userName = chartCake?.name ?? "User"
        let partnerName = otherChart?.name ?? "Partner"

        // Create identity context section
        let identityContext = """
        IDENTITY CONTEXT:
        - You are speaking directly with \(userName)
        - \(userName) is the person using this app and asking questions
        - \(userName)'s chart is the PRIMARY chart in this analysis
        - Always address \(userName) as "you" in your responses
        """

        if otherChart != nil {
            // Synastry & Composite Analysis
            let relationshipType = UserDefaults.standard.string(forKey: "currentRelationshipType") ?? "relationship"

            let partnerContext = """
        - \(partnerName) is \(userName)'s \(relationshipType)
        - \(partnerName) is NOT present in this conversation
        - \(partnerName)'s chart is the SECONDARY chart
        - Refer to \(partnerName) in the third person (he/she/they)
        - When analyzing the synastry between \(userName) and \(partnerName), you are talking TO \(userName) ABOUT \(partnerName)
        - NEVER assume \(userName) is asking on behalf of \(partnerName)
        """

            systemInstructions = """
            \(identityContext)
            \(partnerContext)
            
            You are Lila, an advanced astrology assistant trained in evolutionary astrology, following Steven Forrest's methodology.
            
            🌟 **Relationship Readings (Synastry & Composite)**
            An effective synastry reading requires synthesizing three distinct analytical perspectives. Always structure your analysis in these three phases, clearly distinguishing between them:
            
            🔹 **Gender & Relationship Context:**
            - Chart 1 (\(userName)): \(personsGender ?? "Unknown")
            - Chart 2 (\(partnerName)): \(otherPersonsGender ?? "Unknown")
            - Always begin by asking about the nature of the relationship if not already clear (romantic, family, friendship, professional)
            
            📝 **PHASE ONE: Individual Relationship Dynamics**
            Analyze each person's relational dynamics separately:
            
            1. Begin with a visceral sense of each person's chart:
               - Analyze StrongestPlanet/Sun/Moon/Ascendant triad for each person
               - when any of the os planets are in houses 4-8 as these are the most relational houses
            
            2. Focus on specific relational dynamics:
               - Sun represnets Men in General and Moon represent Women in general and we are either i a relationship with a man or a woman
               - Venus is theruler of affections and gives us info on what we are learning in love (in gemral), specific relationships are seen in the houses (see below for more specififcs) we love our siblings(3rd house) and parents(4th and 8th houses)
               - for romantic relationships, we look mainly at the 5th and 7th house rulers (in the 5th or 7th or ruling the 5th or 7th house cusps)
               - 3rd house is siblings, 4th is the father, 10th is the mother, 5th is the childre, 8th and deeply boddned relations (people that bring our deeper issues to the surface). 11th house for friends
            
            3. For each person, based on the above information, analyze:
               - From an evolutionary perspective, what are they here to learn about intimacy?
               - What are their blindspots and shadow aspects in relationships?
               - What qualities and needs do they bring to intimacy?
               - What is the nature of their "natural mate" - what gifts would that person bring?
            
            📝 **PHASE TWO: Interaction Between Charts**
            
            1. Compare the "feel" of each chart:
               - Think humanly more than technically , meaning compare what yu found above for each person consider how the essenece of each might interact.
               - How do their basic temperaments fit together?
            
            2. Analyze major interaspects:
               - Prioritize interaspects to StrongestPlanet/Sun/Moon/Ascendant/Venus and rulers of teh houses that describe the relationship.
               - as part of interaspect anaylis, its important to note
                house transpositions:
               - Where do important points in one chart fall in the other's houses? when making power interaspects
               - Are there any stelliums in either chart, and where do they fall in the other's houses?
            
            📝 **PHASE THREE: The Composite Chart**
            Analyze the "care and feeding" of the larger whole they create together:
            
            1. Treat the composite chart as its own entity with its own needs and purpose
            
            2. Analyze the "alliances" between the composite chart and both birth charts:
               - Does the composite chart favor one person over the other? ("Feudal System")
               - Does it support each person in different areas? ("Democracy")
               - Is it unlike either person? ("Culture Shock")
            
            3. Examine the composite lunar nodes:
               - What strengths have they brought forward from past connections?
               - What patterns of "stuckness," fears, or wounds might they face?
               - What energies and experiences support their evolutionary momentum together?
            
            💡 **Key Principles:**
            - Frame challenges as opportunities for growth, not fixed fates
            - Keep the three phases clearly distinguished in your presentation
            - Remember that the composite chart has the "tie-breaking vote" in disagreements
            - Use everyday language rather than overly esoteric terminology
            - Guide users toward deeper understanding of the purpose and potentials of their relationships
            """
        } else if transitDate != nil || chartCake?.transits != nil {
            // Transits & Progressions Interpretation
            systemInstructions = """
            \(identityContext)
            
            You are Lila, an advanced astrology assistant trained in evolutionary astrology.
            
            - **Synastry** is about understanding the conditioned thought patterns between two people.
            - **Transits and Progressions** reveal how life unfolds as an evolutionary journey of integration.
            
            Your role is to help \(userName) appreciate why **meaningful events have occurred, are occurring, and will occur**—not as random fate, but as opportunities for growth.
            
            💡 **Life happens for us, not to us.** Every planetary activation represents a **moment in our evolutionary path where we are ready to integrate the two planets in aspect in the 1 or more areas ruled by the natal planet being aspected**.
            
            🌟 How to Interpret Transits & Progressions
            1️⃣ Use Only the Provided Data
            Never estimate planetary movements. Use only the transits & progressions preloaded for the selected date.
            Stick to the given chart. Avoid speculation about planetary positions.
            
            2️⃣ Find the Main House of Concern
            Lila must first determine which house \(userName)'s question is about.
            If the user asks about relationships → 7th house
            If about career → 10th house
            If about spiritual retreats → 12th house
            If no house theme is obvious, ak follow up questions until a house theme becomes obvious.
            
            3️⃣ Prioritize Progressions to House Rulers
            Progressions are the primary indicators of major life themes.
            Lila must always check progressions to the house ruler first—this is the main indicator of why the experience is happening.
            The focus is on what planets are stimulating the house ruler, revealing the Planet responsible for the event.
            these activationg planets will either play teacher or trickster depending on well we handle them. Our job is to warn about the trickster and encourage allowing the stimulating planet to be a teacher.
            
            After progressions, transits to house rulers should be included to fine-tune the timing and expression of these themes.
            ---If there are no progressions to the house rulers, skip straight to tarnsits to house rulers---
            4️⃣ Focus Only on House Rulers
            House rulers determine activations—NOT planets simply transiting a house.
            A transit or progression to a house ruler is the only thing that activates the house.
            Planets inside a house mean nothing unless they rule it.
            All additional transits and progressions must be analyzed in the context of how they support the activation of the main house.
            
            
            🔹 House Rulers =
            ✅ Planets ruling the house cusp
            ✅ Planets inside the house
            ✅ Planets ruling intercepted signs
            
            
            🔑 Key Rules for Interpretation
            ✅ DO:
            ✔ First, determine the main house of concern based on the question.
            ✔ Check for progressions to the house ruler first—this is the main indicator of why the experience is happening.
            ✔ Next, analyze what planets are aspecting the house ruler to see what planets are providing the evolutionry impetus for the event.
            ✔ Only after progressions, check transits to house rulers to fine-tune the timing of the themes.
            ✔ Frame any additional transits in terms of how they support the activation of the main house.
            ✔ Always ask a follow-up question about whether \(userName) would like to know more about how the other current activations to their chart can contribute to the main theme
            ✔ Emphasize the evolutionary lesson of the aspect.
            ✔ Frame challenges as growth opportunities rather than fixed fates.
            ✔ Show how the integration of planetary energies supports soul evolution.
            
            🚫 DON'T:
            ❌ Ignore progressions—progressions are always the first layer of interpretation.
            ❌ Prioritize transits over progressions—transits are secondary fine-tuning, not the main activators.
            ❌ Mention transiting or progressed planets inside a house unless they are making aspects.
            ❌ Interpret transits/progressions unless they aspect the ruler of the main house.
            ❌ Discuss unrelated transits without linking them to the main house activation.
            ❌ Predict outcomes—guide \(userName) to reflect on integration instead.
            """
        } else {
            // Natal Chart Interpretation
            systemInstructions = """
            \(identityContext)
            
            You are Lila, an advanced astrology assistant trained in evolutionary astrology.
            
            🌟 **Natal Chart Interpretation for \(userName)**
            - The natal chart represents \(userName)'s **core psychological makeup** and **life themes.**
            - Every planet represents a **thinking function**, and aspects reveal how these functions integrate.
            
            🔹 **How to Analyze the Natal Chart:**
            1️⃣ Identify the **strongest planet** in \(userName)'s chart (key influence in their life).
            2️⃣ Analyze the **Sun, Moon, and Ascendant** for core identity, emotional needs, and self-presentation.
            3️⃣ Examine **aspects** for key psychological interactions between planetary energies.
            4️⃣ Explain how house rulerships reveal **which life areas are most affected.**
            
            💡 **Reminder:** Encourage self-reflection and understanding rather than fixed predictions.
            """
        }

        return systemInstructions
    }
}
//
//  AIServiceManager.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/2/25.

import Foundation
import SwiftEphemeris
import UIKit
import CoreData

// MARK: - Protocol for AI Service
protocol AIService {
    func generateResponse(
        prompt: String,
        chartCake: ChartCake?,
        otherChart: ChartCake?,
        transitDate: Date?,
        completion: @escaping (Result<String, Error>) -> Void
    )
}

class AIServiceManager {
    static let shared = AIServiceManager()

    var currentService: AIService

    private init() {
        // Initialize with the stored preference or default to OpenAI
        let storedIndex = UserDefaults.standard.integer(forKey: "selectedAIService")

        // Initialize directly without calling instance method
        switch storedIndex {
        case 0:
            currentService = OpenAIAstrologyService(apiKey: APIKeys.openAI)
        case 1:
            currentService =  ClaudeAstrologyService(apiKey: APIKeys.anthropic)
        case 2:
            currentService = HuggingFaceAstrologyService(apiKey: APIKeys.huggingFace)
        default:
            currentService = OpenAIAstrologyService(apiKey: APIKeys.openAI)
        }
    }

    // Method to create a service based on index for later use
    func createServiceForIndex(_ index: Int) -> AIService {
        switch index {
        case 0:
            return OpenAIAstrologyService(apiKey: APIKeys.openAI)
        case 1:
            return ClaudeAstrologyService(apiKey: APIKeys.anthropic)
        case 2:
            return HuggingFaceAstrologyService(apiKey: APIKeys.huggingFace)
        default:
            return OpenAIAstrologyService(apiKey: APIKeys.openAI)
        }
    }
}

// MARK: - AIServiceDelegate Protocol
protocol AIServiceDelegate: AnyObject {
    func didSelectAIService()
}
//
struct MyUserChartProfile {
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

    let moonSign: Zodiac
    let moonHouse: Int
    let moonPower: Double

    let ascendantSign: Zodiac
    let ascendantPower: Double
    let ascendantRulerSigns: [Zodiac]
    let ascendantRulers: [CelestialObject]
    let ascendantRulerHouses: [Int]
    let ascendantRulerPowers: [Double]
   

    let dominantHouseScores: [Int: Double]
    let dominantSignScores: [Zodiac: Double]
    let dominantPlanetScores: [CelestialObject: Double]

    let mostHarmoniousPlanet: CelestialObject
    let mostDiscordantPlanet: CelestialObject

    let topAspectsToStrongestPlanet: [NatalAspectScore]
    let topAspectsToMoon: [NatalAspectScore]
    let topAspectsToAscendant: [NatalAspectScore]
    let topAspectsToAscendantRulers: [NatalAspectScore]
}

import Foundation
import SwiftEphemeris
import UIKit
import CoreData

class AIServiceController: UIViewController {

    // MARK: - Properties
    weak var delegate: AIServiceDelegate?

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Choose AI Service"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private lazy var serviceSelector: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["OpenAI", "Claude", "HuggingFace"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "selectedAIService")
        segmentedControl.addTarget(self, action: #selector(serviceChanged(_:)), for: .valueChanged)
        return segmentedControl
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Select your preferred AI service for astrology readings"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var serviceInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Confirm Selection", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(confirmSelection), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties
    private var currentServiceIndex: Int {
        return serviceSelector.selectedSegmentIndex
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateServiceInfo()

        // Set up navigation
        title = "AI Service"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(serviceSelector)
        view.addSubview(serviceInfoLabel)
        view.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Service Selector
            serviceSelector.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            serviceSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            serviceSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Service Info Label
            serviceInfoLabel.topAnchor.constraint(equalTo: serviceSelector.bottomAnchor, constant: 40),
            serviceInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            serviceInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Confirm Button
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 200),
            confirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func serviceChanged(_ sender: UISegmentedControl) {
        updateServiceInfo()
    }

    @objc private func confirmSelection() {
        // Save selection to UserDefaults
        UserDefaults.standard.set(serviceSelector.selectedSegmentIndex, forKey: "selectedAIService")

        // Set the selected service as the active one for the app
        let selectedService = createServiceForIndex(serviceSelector.selectedSegmentIndex)
        AIServiceManager.shared.currentService = selectedService

        // Notify delegate
        delegate?.didSelectAIService()

        // Dismiss the view controller
        dismiss(animated: true)
    }

    // MARK: - Helper Methods
    private func updateServiceInfo() {
        serviceInfoLabel.text = serviceInfoText(for: serviceSelector.selectedSegmentIndex)
    }

    private func createServiceForIndex(_ index: Int) -> AIService {
        switch index {
        case 0:
            return OpenAIAstrologyService(apiKey: APIKeys.openAI)
        case 1:
            return ClaudeAstrologyService(apiKey: APIKeys.anthropic)
        case 2:
            return HuggingFaceAstrologyService(apiKey: APIKeys.huggingFace)
        default:
            return OpenAIAstrologyService(apiKey: APIKeys.openAI)
        }
    }

    private func serviceTypeString(for index: Int) -> String {
        switch index {
        case 0:
            return "OpenAI"
        case 1:
            return "Claude"
        case 2:
            return "HuggingFace"
        default:
            return "OpenAI"
        }
    }

    private func serviceInfoText(for index: Int) -> String {
        switch index {
        case 0:
            return """
            OpenAI (GPT-4o)
            
            • Highly accurate astrological interpretations
            • Fast response times
            • Excellent for detailed natal chart readings
            • Best for technical astrological questions
            
            This service uses OpenAI's GPT-4o model, which offers advanced understanding of astrological concepts and detailed interpretations.
            """
        case 1:
            return """
            Claude (3.7 Sonnet)
            
            • Nuanced emotional interpretations
            • Excellent for relationship readings
            • More narrative and storytelling approach
            • May provide deeper spiritual insights
            
            This service uses Anthropic's Claude 3.7 Sonnet model, which excels at understanding the emotional and relational aspects of astrology.
            """
        case 2:
            return """
            HuggingFace (Mistral)
            
            • Open source alternative
            • More concise responses
            • May require more specific questioning
            • Less resource-intensive
            
            This service uses Mistral's 7B model via HuggingFace, offering a lightweight alternative that works well for straightforward astrological questions.
            """
        default:
            return ""
        }
    }
}
enum ReadingType: String {
    case natal = "NATAL CHART"
    case transits = "TRANSIT & PROGRESSION"
    case synastry = "SYNASTRY/RELATIONSHIP"
}

class AgentPromptBuilder {
    
    var cake: ChartCake!
   
    
    
     func buildContext(for readingType: ReadingType, userChart: ChartCake, partnerChart: ChartCake? = nil) -> String {
         let profile = userChart.buildUserChartProfile()
        let natalPrompt = NatalPromptGenerator.generatePrompt(from: profile)
        let age = calculateAgeString(from: userChart.natal.birthDate, to: Date())
      
        var context = ""

        switch readingType {
        case .natal:
            context += """
            \(natalPrompt)

            HOUSE RULERSHIPS:
            \(formatHouseRulerships(for: userChart))
            """

        case .transits:
            let date = userChart.transits.transitDate
            let dateString = date?.formatted(date: .abbreviated, time: .omitted) ?? "today"

            context += """
            \(natalPrompt)

            TRANSIT DATA for \(dateString):
            - Most important activations: \(userChart.netOne())
            - Supporting activations: \(userChart.netTwo())
            - Slightly less important: \(userChart.netThree())
            - Daily triggers: \(userChart.netFour())
            - This person is \(age). Please make recommendations age-appropriate.

            HOUSE RULERSHIPS:
            \(formatHouseRulerships(for: userChart))
            """

        case .synastry:
            guard let partner = partnerChart else {
                return "\(natalPrompt)\n\n❗ Missing partner chart for synastry reading."
            }

            // 👇 Build partner profile
            let partnerProfile = partner.buildUserChartProfile()
            let partnerPrompt = NatalPromptGenerator.generatePrompt(from: partnerProfile)

            let synastry = generateSynastryData(userChart: userChart, partnerChart: partner)

            context += """
            \(natalPrompt)

            ❤️ SYNASTRY DATA:

            📎 PARTNER'S PROFILE:
            \(partnerPrompt)

            🔗 CONNECTIONS:
            \(synastry)
            """

        }

        return context
    }

    private func generateSynastryData(userChart: ChartCake, partnerChart: ChartCake) -> String {
        let userName = userChart.name ?? "User"
        let partnerName = partnerChart.name ?? "Partner"
        
        // Create SynastryChart
        let synastryChart = SynastryChart(chart1: userChart.natal, chart2: partnerChart.natal, name1: userName, name2: partnerName)
        
        let userCoordinates = userChart.natal.planets.map { $0 }
        let partnerCoordinates = partnerChart.natal.planets.map { $0 }

        // 🌟 INTERASPECTS
        let interaspects = synastryChart.interAspects(
            rickysPlanets: userCoordinates,
            linneasPlanets: partnerCoordinates,
            name1: userName,
            name2: partnerName
        )
        let aspectScores = synastryChart.interchartAspectScores(aspects: interaspects, name1: userName, name2: partnerName)
        let topAspects = aspectScores.prefix(10)

        var synastryData = "TOP 10 STRONGEST INTERASPECTS:\n"
        for (aspect, score) in topAspects {
            synastryData += "• \(aspect.body1.body.keyName) (\(userName)) \(aspect.kind.description) \(aspect.body2.body.keyName) (\(partnerName)) - Orb: \(String(format: "%.1f", aspect.orbDelta))° - Strength: \(String(format: "%.1f", score))\n"
        }

        // 🏠 PLANETS IN HOUSES
        synastryData += "\n\(userName)'S PLANETS IN \(partnerName)'S HOUSES:\n"
        let userInPartnerHouses = synastryChart.othersPlanetInHouses(using: partnerChart.natal.houseCusps, with: userCoordinates)
        for (house, planets) in userInPartnerHouses.sorted(by: { $0.key < $1.key }) {
            synastryData += "House \(house): \(planets.map { $0.keyName }.joined(separator: ", "))\n"
        }

        synastryData += "\n\(partnerName)'S PLANETS IN \(userName)'S HOUSES:\n"
        let partnerInUserHouses = synastryChart.othersPlanetInHouses(using: userChart.natal.houseCusps, with: partnerCoordinates)
        for (house, planets) in partnerInUserHouses.sorted(by: { $0.key < $1.key }) {
            synastryData += "House \(house): \(planets.map { $0.keyName }.joined(separator: ", "))\n"
        }

        // 🌞 COMPOSITE CHART (Midpoint Method)
        let compositeChart = Chart(alpha: userChart.natal, bravo: partnerChart.natal)
        let coords = compositeChart.rickysBodies

        let dominantPlanetScores = compositeChart.getTotalPowerScoresForPlanetsCo(coords)
        let strongest = dominantPlanetScores.max { $0.value < $1.value }?.key.body
        let dominantHouseScores = compositeChart.calculateHouseStrengths(coords)

        let topCompositeAspects = compositeChart
            .planets
            .flatMap { p in
                compositeChart.filterAndFormatNatalAspects(by: p.body, aspectsScores: compositeChart.allCelestialAspectScoresByAspect())
            }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "\($0.key.body1.body.keyName) \($0.key.kind.description) \($0.key.body2.body.keyName) (Score: \($0.value.rounded(toPlaces: 2)))" }

        synastryData += """

        🌀 COMPOSITE CHART OVERVIEW:
        - Composite Sun: \(compositeChart.sun.sign.keyName)
        - Composite Moon: \(compositeChart.moon.sign.keyName)
        - Composite Ascendant: \(compositeChart.ascendantCoordinate.sign.keyName)
        - Strongest Composite Planet: \(strongest?.keyName)
        - Top Composite Aspects:
          \(topCompositeAspects.joined(separator: "\n  "))
        - Dominant Houses: \(dominantHouseScores.sorted(by: { $0.value > $1.value }).prefix(3).map { "House \($0.key): \($0.value.rounded(toPlaces: 2))" }.joined(separator: ", "))
        """

        return synastryData
    }

    
    private func formatHouseRulerships(for cake: ChartCake) -> String {
        (1...12).map { house in
            let rulers = cake.rulingBodies(for: house).map { $0.body.keyName }
            return "• \(house)th House: \(rulers.joined(separator: ", "))"
        }.joined(separator: "\n")
    }
}
