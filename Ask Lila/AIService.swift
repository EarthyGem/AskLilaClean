import SwiftEphemeris
import Foundation


// MARK: - Base Astrology AI Service
class BaseAstrologyService {
    
    var chartCake: ChartCake!
    // Common astrology reference data
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
    
    let giftGiverAndThief: String = """
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
    
    // Common planetary attributes
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
        "Moon": [
            "Urge": "Domestic",
            "Function": [
                "The development of the ability to feel or to respond emotionally",
                "The development of subjectivity, impressionability, and sensitivity",
                "The development of what we might call a soul"
            ],
            "Dysfunction": [
                "Emotional self-indulgence", "timidity", "laziness", "wishy-washiness",
                "overactive imagination", "indecision", "moodiness"
            ],
            "Key Questions": [
                "What kinds of experiences are most essential to my happiness?",
                "When moodiness and irrationality overtake me, how are they expressed?",
                "What unconscious emotional needs motivate my behavior?"
            ]
        ]
        // Additional planets would be added here
    ]
    
    // House attributes
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
        ]
        // Additional houses would be added here
    ]
    
   
    func returnPlanets() -> String {
        let allAspectScores = chartCake.allCelestialAspectScoresByAspect()
        let age = calculateAgeString(from: chartCake.natal.birthDate, to: Date())

        var informationToCopy = """
          natal placements for child: \(chartCake.filterAndFormatAllPlanets(aspectsScores: allAspectScores, celestialObjects: chartCake.natal.planets))
          
          planet scores for child: \(chartCake.natal.calculatePlanetMetrics())
          house scores for child: \(chartCake.natal.calculateHouseMetrics())
          sign scores for child: \(chartCake.natal.calculateSignMetrics())
        
          most important activations for child: \(chartCake.netOne())
          other important activations for child: \(chartCake.netTwo())
          slightly less important activations for child: \(chartCake.netThree()) 
        \(chartCake.netFour())
          this child is \(String(describing: age)). Please ake recomendations age appropriate
          The Houses Ruled by Each Planet
          \(chartCake.natal.houseCusps.rulersForAllCusps())
        """

        print(informationToCopy)
        return informationToCopy
    }

    func generateAstrologyContext(chartCake: ChartCake?, otherChart: ChartCake? = nil) -> String {
        guard let chart = chartCake else {
            return "No chart data available."
        }
        
        // Format House Rulerships (basic data that shouldn't cause issues)
        let houseRulerships: [String: [String]] = (1...12).reduce(into: [String: [String]]()) { dict, houseNumber in
            dict["\(houseNumber)th House"] = chart.rulingBodies(for: houseNumber).compactMap { $0.body.keyName }
        }
        
        // Basic natal chart info
        var context = """
        NATAL CHART BASICS:
        
        
        HOUSE RULERSHIPS:
        \(houseRulerships.map { "- \($0.key): \($0.value.joined(separator: ", "))" }.joined(separator: "\n"))
        """

        return context
    }
    }
    // Determine system instructions based on context
    func getSystemInstructions(chartCake: ChartCake?, otherChart: ChartCake?, transitDate: Date?) -> String {
        var systemInstructions = ""

        if otherChart != nil {
            // If another person's chart is selected → Synastry & Composite Interpretation
            systemInstructions = """
            You are Lila, an advanced astrology assistant trained in evolutionary astrology.

            🌟 **Relationship Readings (Synastry & Composite)**
            - Focus on the **dynamics between the two individuals.**
            - **Synastry** analyzes how one person's chart activates the other.
            - **Composite** represents the relationship as an independent entity.

            🔹 **How to Analyze Synastry:**
            1️⃣ Identify inter-aspects between natal planets of each individual.
            2️⃣ Pay close attention to aspects involving **Venus, Mars, the Moon, and the Ascendant.**
            3️⃣ Explain how each person activates different parts of the other's psyche.

            🔹 **How to Analyze the Composite Chart:**
            1️⃣ Treat it as the "soul" of the relationship.
            2️⃣ Focus on **Sun, Moon, Venus, and the Ascendant** in the composite.
            3️⃣ Consider if the composite supports or challenges the individuals.

            💡 **Reminder:** Guide users toward deeper understanding, not deterministic predictions.
            """
        } else if transitDate != nil {
            // If a date is selected → Transits & Progressions Interpretation
            systemInstructions = """
                 You are Lila, an advanced astrology assistant trained in evolutionary astrology.

                 - **Synastry** is about understanding the conditioned thought patterns between two people.
                 - **Transits and Progressions** reveal how life unfolds as an evolutionary journey of integration.

                 Your role is to help users appreciate why **meaningful events have occurred, are occurring, and will occur**—not as random fate, but as opportunities for growth.

                 💡 **Life happens for us, not to us.** Every planetary activation represents a **moment in our evolutionary path where we are ready to integrate the two planets in aspect in the 1 or more areas ruled by the natal planet being aspected**.

                 🌟 How to Interpret Transits & Progressions
                 1️⃣ Use Only the Provided Data
                 Never estimate planetary movements. Use only the transits & progressions preloaded for the selected date.
                 Stick to the given chart. Avoid speculation about planetary positions.

                 2️⃣ Find the Main House of Concern
                 Lila must first determine which house the user's question is about.
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
                 ✔ Always ask a follow-up question about whether the would like to know more about how the other current activations to your chart can contribute to the main theme
                 ✔ Emphasize the evolutionary lesson of the aspect.
                 ✔ Frame challenges as growth opportunities rather than fixed fates.
                 ✔ Show how the integration of planetary energies supports soul evolution.

                 🚫 DON'T:
                 ❌ Ignore progressions—progressions are always the first layer of interpretation.
                 ❌ Prioritize transits over progressions—transits are secondary fine-tuning, not the main activators.
                 ❌ Mention transiting or progressed planets inside a house unless they are making aspects.
                 ❌ Interpret transits/progressions unless they aspect the ruler of the main house.
                 ❌ Discuss unrelated transits without linking them to the main house activation.
                 ❌ Predict outcomes—guide the user to reflect on integration instead.
            """
        } else {
            // If neither a date nor a partner is selected → Natal Chart Interpretation
            systemInstructions = """
            You are Lila, an advanced astrology assistant trained in evolutionary astrology.

            🌟 **Natal Chart Interpretation**
            - The natal chart represents the user's **core psychological makeup** and **life themes.**
            - Every planet represents a **thinking function**, and aspects reveal how these functions integrate.

            🔹 **How to Analyze the Natal Chart:**
            1️⃣ Identify the **strongest planet** in the user's chart (key influence in their life).
            2️⃣ Analyze the **Sun, Moon, and Ascendant** for core identity, emotional needs, and self-presentation.
            3️⃣ Examine **aspects** for key psychological interactions between planetary energies.
            4️⃣ Explain how house rulerships reveal **which life areas are most affected.**

            💡 **Reminder:** Encourage self-reflection and understanding rather than fixed predictions.
            """
        }

        return systemInstructions
    }


class OpenAIAstrologyService: BaseAstrologyService, AIService {
    private let apiKey: String
    private let model: String
    private let maxTokens: Int
    
    init(apiKey: String, model: String = "gpt-4o", maxTokens: Int = 2000) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        super.init()
    }
    
    func generateResponse(
        prompt: String,
        chartCake: ChartCake?,
        otherChart: ChartCake?,
        transitDate: Date?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Get conversation history (last 5 messages to avoid token limits)
        let conversationHistory = Array(LilaMemoryManager.shared.fetchConversationHistory().suffix(5))
        let messageHistory = conversationHistory.compactMap { message -> [String: String]? in
            guard let role = message.role?.lowercased(), let content = message.content else {
                return nil
            }
            return ["role": role == "assistant" ? "assistant" : "user", "content": content]
        }
 
        // Combine system instructions with context for more cohesive understanding
     let systemMessage = "You are Lila, an advanced astrology assistant trained in evolutionary astrology. The full user prompt will contain all context you need."

        
        // Build comprehensive message array
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemMessage]
        ]
        
        // Add conversation history
        messages.append(contentsOf: messageHistory)
        
        // Add current user prompt
        messages.append(["role": "user", "content": prompt])
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "top_p": 0.95
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("❌ ERROR: Invalid API URL")
            completion(.failure(NSError(domain: "OpenAIAstrologyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // Log request size to help with token estimation
            print("📦 OpenAI Request Size: \(jsonData.count / 1024) KB")
        } catch {
            print("❌ ERROR: Failed to serialize request body - \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard self != nil else { return }
            
            if let error = error {
                print("❌ OpenAI Request failed at network layer: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("🔍 URLError Code: \(urlError.code.rawValue) – \(urlError.code)")
                }
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 HTTP Status Code: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errMsg = errorResponse["error"] as? [String: Any],
                       let message = errMsg["message"] as? String {
                        print("❌ API Error Message: \(message)")
                    } else {
                        print("❌ Non-200 status code with no clear error body")
                    }
                    completion(.failure(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No data received from OpenAI")
                completion(.failure(NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 OpenAI Raw Response: \(responseString.prefix(300))...")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let choices = json?["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("✅ OpenAI success — saving response")
                    LilaMemoryManager.shared.saveMessage(role: "assistant", content: content)
                    completion(.success(content))
                } else {
                    print("❌ Response was missing choices/content — fallback debugging:")
                    print("🛠 JSON Dump: \(String(describing: json))")
                    completion(.failure(NSError(domain: "OpenAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "No content found"])))
                }
            } catch {
                print("❌ JSON parsing failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Claude Astrology Service
class ClaudeAstrologyService: BaseAstrologyService, AIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model: String
    private let version = "2023-06-01"
    private let maxTokens: Int
    
    init(apiKey: String, model: String = "claude-3-7-sonnet-20250219", maxTokens: Int = 4000) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        super.init()
    }
    
    func generateResponse(
        prompt: String,
        chartCake: ChartCake?,
        otherChart: ChartCake?,
        transitDate: Date?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let conversationHistory = Array(LilaMemoryManager.shared.fetchConversationHistory().suffix(5))
        var messages: [[String: Any]] = []

        for message in conversationHistory {
            if let role = message.role?.lowercased(), let content = message.content {
                let claudeRole = role == "assistant" ? "assistant" : "user"
                messages.append([
                    "role": claudeRole,
                    "content": [[ "type": "text", "text": content ]]
                ])
            }
        }

        let enhancedSystemPrompt = "You are Lila, an advanced astrology assistant trained in evolutionary astrology. The full user prompt will contain all chart context and analysis instructions."

        // Combine system instructions with context for more cohesive understanding
        let userMessage = prompt


        messages.append([
            "role": "user",
            "content": [[ "type": "text", "text": userMessage ]]
        ])

        let requestDict: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "system": enhancedSystemPrompt,
            "messages": messages
        ]

        guard let url = URL(string: baseURL) else {
            print("❌ ERROR: Invalid API URL")
            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }

        // ✅ Move try inside do-catch block for proper error handling
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestDict)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue(version, forHTTPHeaderField: "anthropic-version")

            print("📦 Claude Request Size: \(jsonData.count / 1024) KB")

            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard self != nil else { return }

                if let error = error {
                    print("❌ Claude API Request Failed - \(error.localizedDescription)")
                    if let urlError = error as? URLError {
                        print("🔍 URLError Code: \(urlError.code.rawValue) – \(urlError.code)")
                    }
                    completion(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Claude HTTP Status Code: \(httpResponse.statusCode)")
                    if !(200...299).contains(httpResponse.statusCode) {
                        if let data = data,
                           let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorInfo = errorJson["error"] as? [String: Any],
                           let errorMessage = errorInfo["message"] as? String {
                            print("📝 Claude Error Message: \(errorMessage)")
                            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        } else {
                            print("❌ Claude returned non-200 with no error message")
                            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])))
                        }
                        return
                    }
                }

                guard let data = data else {
                    print("❌ No data received from Claude")
                    completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }

                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Claude Raw Response: \(responseString.prefix(300))...")
                }

                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let content = responseJson?["content"] as? [[String: Any]] {
                        let texts = content.compactMap { $0["text"] as? String }
                        let reply = texts.joined()

                        if !reply.isEmpty {
                            LilaMemoryManager.shared.saveMessage(role: "assistant", content: reply)
                            print("✅ Claude Response saved")
                            completion(.success(reply))
                        } else {
                            print("❌ Claude content empty")
                            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty Claude content"])))
                        }
                    } else {
                        print("❌ Claude response missing 'content'")
                        print("📄 Raw: \(String(data: data, encoding: .utf8) ?? "N/A")")
                        completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing content field"])))
                    }
                } catch {
                    print("❌ JSON Decoding Failed for Claude - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }

            task.resume()
        } catch {
            print("❌ ERROR: Failed to serialize requestDict - \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

}

                            // MARK: - HuggingFace Astrology Service
                            class HuggingFaceAstrologyService: BaseAstrologyService, AIService {
                                private let apiKey: String
                                private let baseURL = "https://api-inference.huggingface.co/models/"
                                private let model: String
                                
                                init(apiKey: String = APIKeys.huggingFace, model: String = "mistralai/Mistral-7B-Instruct-v0.2") {
                                    self.apiKey = apiKey
                                    self.model = model
                                    super.init()
                                }
                                
                                func generateResponse(
                                    prompt: String,
                                    chartCake: ChartCake?,
                                    otherChart: ChartCake?,
                                    transitDate: Date?,
                                    completion: @escaping (Result<String, Error>) -> Void
                                ) {
                                    
                                    // Generate astrology context
                                    let formattedPrompt = """
                                    <s>[INST] <<SYS>>
                                    You are Lila, an advanced astrology assistant trained in evolutionary astrology.
                                    <</SYS>>

                                    \(prompt)
                                    [/INST]
                                    """

                                    // Define API endpoint
                                    guard let url = URL(string: "\(baseURL)\(model)") else {
                                        print("❌ ERROR: Invalid API URL")
                                        completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
                                        return
                                    }
                                    
                                    // Create request parameters
                                    let parameters: [String: Any] = [
                                        "inputs": formattedPrompt,
                                        "parameters": [
                                            "max_new_tokens": 2000,
                                            "temperature": 0.7,
                                            "top_p": 0.95,
                                            "do_sample": true,
                                            "return_full_text": false
                                        ]
                                    ]
                                    
                                    // Convert to JSON data
                                    guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
                                        print("❌ ERROR: Failed to serialize request body")
                                        completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON data"])))
                                        return
                                    }
                                    
                                    // Create and configure request
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "POST"
                                    request.httpBody = jsonData
                                    
                                    // Set headers
                                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                                    
                                    // Debug info
                                    print("🔍 Making HuggingFace API request to model: \(model)")
                                    
                                    // Make request
                                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                        if let error = error {
                                            print("❌ HuggingFace API Request Failed - \(error.localizedDescription)")
                                            if let urlError = error as? URLError {
                                                print("🔍 URLError Code: \(urlError.code.rawValue) – \(urlError.code)")
                                            }
                                            completion(.failure(error))
                                            return
                                        }
                                        
                                        if let httpResponse = response as? HTTPURLResponse {
                                            print("🌐 HuggingFace HTTP Status Code: \(httpResponse.statusCode)")
                                            if !(200...299).contains(httpResponse.statusCode) {
                                                if let data = data,
                                                   let responseText = String(data: data, encoding: .utf8) {
                                                    print("❌ HuggingFace API Error Response: \(responseText.prefix(300))...")
                                                }
                                                completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])))
                                                return
                                            }
                                        }
                                        
                                        guard let data = data else {
                                            print("❌ No data from HuggingFace")
                                            completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                                            return
                                        }
                                        
                                        if let responseString = String(data: data, encoding: .utf8) {
                                            print("📥 HuggingFace Raw Response: \(responseString.prefix(300))...")
                                        }
                                        
                                        do {
                                            // Try array format first
                                            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                                               let first = jsonArray.first,
                                               let generated = first["generated_text"] as? String {
                                                print("✅ HuggingFace Response (array format)")
                                                LilaMemoryManager.shared.saveMessage(role: "assistant", content: generated)
                                                completion(.success(generated))
                                                return
                                            }
                                            
                                            // Try object format fallback
                                            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                                if let error = jsonObject["error"] as? String {
                                                    print("❌ HuggingFace Model Error: \(error)")
                                                    completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 2, userInfo: [NSLocalizedDescriptionKey: error])))
                                                    return
                                                }
                                                
                                                if let generatedText = jsonObject["generated_text"] as? String {
                                                    print("✅ HuggingFace Response (object format)")
                                                    LilaMemoryManager.shared.saveMessage(role: "assistant", content: generatedText)
                                                    completion(.success(generatedText))
                                                    return
                                                }
                                            }
                                            
                                            print("❌ HuggingFace response unrecognized")
                                            completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown HuggingFace format"])))
                                            
                                        } catch {
                                            print("❌ JSON Parsing Failed - HuggingFace - \(error.localizedDescription)")
                                            completion(.failure(error))
                                        }
                                    }
                                }

                            }

                            // MARK: - AI Service Factory
                            class AstrologyAIServiceFactory {
                                enum ServiceType {
                                    case openAI
                                    case claude
                                    case huggingFace
                                }
                                
                                static func createService(type: ServiceType) -> AIService {
                                    switch type {
                                    case .openAI:
                                        return OpenAIAstrologyService(apiKey: APIKeys.openAI)
                                    case .claude:
                                        return ClaudeAstrologyService(apiKey: APIKeys.anthropic)
                                    case .huggingFace:
                                        return HuggingFaceAstrologyService(apiKey: APIKeys.huggingFace)
                                    }
                                }
                            }
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
