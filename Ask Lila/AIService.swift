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
  


class OpenAIAstrologyService: BaseAstrologyService, AIService {
    private let apiKey: String
    private let model: String
    private let maxTokens: Int
    
    init(apiKey: String, model: String = "gpt-4o", maxTokens: Int = 1000) {
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
                    if let usage = json?["usage"] as? [String: Any],
                       let promptTokens = usage["prompt_tokens"] as? Int,
                       let completionTokens = usage["completion_tokens"] as? Int,
                       let totalTokens = usage["total_tokens"] as? Int {

                        let cost = AICostManager.estimateCost(
                            model: self!.model,
                            inputTokens: promptTokens,
                            outputTokens: completionTokens
                        )

                        let entry = AICostEntry(
                            model: self!.model,
                            inputTokens: promptTokens,
                            outputTokens: completionTokens,
                            totalTokens: totalTokens,
                            costUSD: cost,
                            readingType: LilaMemoryManager.shared.determineReadingType(),
                            chartName: chartCake?.natal.name ?? "Unknown",
                            timestamp: Date()
                        )

                        AICostLogger.shared.log(entry)
                    }

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
    
    init(apiKey: String, model: String = "claude-3-7-sonnet-20250219", maxTokens: Int = 1000) {
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

        messages.append([
            "role": "user",
            "content": [[ "type": "text", "text": prompt ]]
        ])

        let requestDict: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "system": enhancedSystemPrompt,
            "messages": messages
        ]

        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }

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
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }

                do {
                    let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let content = responseJson?["content"] as? [[String: Any]] {
                        let texts = content.compactMap { $0["text"] as? String }
                        let reply = texts.joined()

                        if !reply.isEmpty {
                            LilaMemoryManager.shared.saveMessage(role: "assistant", content: reply)

                            // 🔢 Estimate token usage
                            let inputTokens = prompt.split(separator: " ").count
                            let outputTokens = reply.split(separator: " ").count
                            let totalTokens = inputTokens + outputTokens

                            // 💰 Estimate cost
                            let cost = AICostManager.estimateCost(model: self?.model ?? "claude-3-sonnet", inputTokens: inputTokens, outputTokens: outputTokens)

                            let entry = AICostEntry(
                                model: self?.model ?? "claude-3-sonnet",
                                inputTokens: inputTokens,
                                outputTokens: outputTokens,
                                totalTokens: totalTokens,
                                costUSD: cost,
                                readingType: LilaMemoryManager.shared.determineReadingType(),
                                chartName: chartCake?.natal.name ?? "Unknown",
                                timestamp: Date()
                            )

                            AICostLogger.shared.log(entry)

                            completion(.success(reply))
                        } else {
                            completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty Claude content"])))
                        }
                    } else {
                        completion(.failure(NSError(domain: "ClaudeAstrologyService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing content field"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }

            task.resume()
        } catch {
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
        let formattedPrompt = """
        <s>[INST] <<SYS>>
        You are Lila, an advanced astrology assistant trained in evolutionary astrology.
        <</SYS>>

        \(prompt)
        [/INST]
        """

        guard let url = URL(string: "\(baseURL)\(model)") else {
            completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

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

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON data"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                // Try array format
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let first = jsonArray.first,
                   let generated = first["generated_text"] as? String {
                    
                    // 🔢 Estimate token usage
                    let inputTokens = formattedPrompt.split(separator: " ").count
                    let outputTokens = generated.split(separator: " ").count
                    let totalTokens = inputTokens + outputTokens

                    // 💰 Estimate cost
                    let cost = AICostManager.estimateCost(model: self.model, inputTokens: inputTokens, outputTokens: outputTokens)

                    let entry = AICostEntry(
                        model: self.model,
                        inputTokens: inputTokens,
                        outputTokens: outputTokens,
                        totalTokens: totalTokens,
                        costUSD: cost,
                        readingType: LilaMemoryManager.shared.determineReadingType(),
                        chartName: chartCake?.natal.name ?? "Unknown",
                        timestamp: Date()
                    )

                    AICostLogger.shared.log(entry)

                    LilaMemoryManager.shared.saveMessage(role: "assistant", content: generated)
                    completion(.success(generated))
                    return
                }

                // Try object format fallback
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let generatedText = jsonObject["generated_text"] as? String {

                    // 🔢 Estimate token usage
                    let inputTokens = formattedPrompt.split(separator: " ").count
                    let outputTokens = generatedText.split(separator: " ").count
                    let totalTokens = inputTokens + outputTokens

                    // 💰 Estimate cost
                    let cost = AICostManager.estimateCost(model: self.model, inputTokens: inputTokens, outputTokens: outputTokens)

                    let entry = AICostEntry(
                        model: self.model,
                        inputTokens: inputTokens,
                        outputTokens: outputTokens,
                        totalTokens: totalTokens,
                        costUSD: cost,
                        readingType: LilaMemoryManager.shared.determineReadingType(),
                        chartName: chartCake?.natal.name ?? "Unknown",
                        timestamp: Date()
                    )

                    AICostLogger.shared.log(entry)

                    LilaMemoryManager.shared.saveMessage(role: "assistant", content: generatedText)
                    completion(.success(generatedText))
                    return
                }

                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = jsonObject["error"] as? String {
                    completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 2, userInfo: [NSLocalizedDescriptionKey: error])))
                    return
                }

                completion(.failure(NSError(domain: "HuggingFaceAstrologyService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown HuggingFace format"])))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
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
