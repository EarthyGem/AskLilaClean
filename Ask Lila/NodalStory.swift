import Foundation
import SwiftEphemeris

class SouthNodeStorytellerService {
    // API key for your preferred AI provider
    private let apiKey: String
    private let model: String
    private let chartCake: ChartCake
    private let provider: AIProvider
    
    // MARK: - Enums
    
    enum AIProvider {
        case openAI
        case claude
        case huggingFace
    }
    
    enum SouthNodeStoryError: Error, LocalizedError {
        case invalidURL
        case apiError(String, Int?)
        case decodingError
        case networkError(Error)
        case unauthorized
        case rateLimited
        case modelLoading
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .apiError(let message, let code):
                if let code = code {
                    return "API Error (\(code)): \(message)"
                }
                return "API Error: \(message)"
            case .decodingError:
                return "Failed to decode API response"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .unauthorized:
                return "Unauthorized: Please check your API key"
            case .rateLimited:
                return "Rate limited: Please try again later"
            case .modelLoading:
                return "Model is still loading. Please try again in a minute."
            }
        }
    }
    
    // MARK: - Initializer
    
    init(chartCake: ChartCake, apiKey: String, provider: AIProvider, model: String? = nil) {
        self.chartCake = chartCake
        self.apiKey = apiKey
        self.provider = provider
        
        // Set default model based on provider if not specified
        switch provider {
        case .openAI:
            self.model = model ?? "gpt-4o"
        case .claude:
            self.model = model ?? "claude-3-7-sonnet-20250219"
        case .huggingFace:
            self.model = model ?? "mistralai/Mistral-7B-Instruct-v0.2"
        }
    }
    
    // MARK: - Story Generation
    
    func generateSouthNodeStory(
        gender: String,
        timePeriod: String,
        style: String,
        length: String,
        completion: @escaping (Result<String, SouthNodeStoryError>) -> Void
    ) {
        // Extract South Node information from chartCake
        let rawNodalStory = chartCake.generateFullNodalStory2(with: chartCake)
        let firstName = chartCake.name.components(separatedBy: " ").first ?? "They"
        
        // Get the actual time period (handle "Random" selection)
        let selectedTimePeriod = timePeriod == "Random" ? getRandomTimePeriod() : timePeriod
        
        // Create appropriately formatted prompt based on the provider
        let (prompt, maxTokens) = createProviderSpecificPrompt(
            southNodeInfo: rawNodalStory,
            firstName: firstName,
            gender: gender,
            selectedTimePeriod: selectedTimePeriod,
            stylePrompt: getStylePrompt(style),
            lengthInstruction: getLengthParameters(length).1,
            maxTokens: getLengthParameters(length).0
        )
        
        // Send request to the appropriate API
        switch provider {
        case .openAI:
            sendOpenAIRequest(prompt: prompt, maxTokens: maxTokens, completion: completion)
        case .claude:
            sendClaudeRequest(prompt: prompt, maxTokens: maxTokens, completion: completion)
        case .huggingFace:
            sendHuggingFaceRequest(prompt: prompt, maxTokens: maxTokens, completion: completion)
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper function to get random time period
    private func getRandomTimePeriod() -> String {
        let timePeriodOptions = [
            "Ancient Egypt",
            "Mesopotamia",
            "Ancient Greece",
            "Ancient Rome",
            "Persian Empire",
            "Ancient China",
            "Mesoamerica (Aztec, Maya, Olmec, Inca)",
            "Indus Valley Civilization",
            "African Kingdoms (Mali, Zulu, Kush, Aksum)",
            "Medieval Europe",
            "Viking Age",
            "Byzantine Empire",
            "Mongol Empire",
            "Islamic Golden Age",
            "Feudal Japan (Samurai & Shogunate)",
            "Renaissance Italy",
            "Ottoman Empire",
            "Victorian England",
            "Spanish Conquest of the Americas",
            "Age of Exploration (1400s-1600s)",
            "French Revolution & Napoleonic Era",
            "Elizabethan England",
            "Industrial Revolution",
            "Antebellum South",
            "American Wild West",
            "Russian Empire",
            "British Raj (Colonial India)",
            "World War I",
            "Roaring Twenties & Prohibition",
            "World War II"
        ]
        
        return timePeriodOptions.randomElement() ?? "Medieval Europe"
    }
    
    private func getLengthParameters(_ length: String) -> (Int, String) {
        switch length {
        case "Short":
            // OpenAI tends to use fewer tokens per word than Claude and HuggingFace
            let openAITokens = 1500
            let claudeTokens = 1800
            let huggingFaceTokens = 2000
            
            let maxTokens = provider == .openAI ? openAITokens :
                            provider == .claude ? claudeTokens : huggingFaceTokens
            
            return (maxTokens, "Write a concise story around 700-1000 words. Focus on key moments and essential character development.")
            
        case "Medium":
            let openAITokens = 3000
            let claudeTokens = 3500
            let huggingFaceTokens = 4000
            
            let maxTokens = provider == .openAI ? openAITokens :
                            provider == .claude ? claudeTokens : huggingFaceTokens
            
            return (maxTokens, "Write a moderately detailed story around 1500-2000 words. Include character development and setting details.")
            
        case "Long":
            let openAITokens = 4500
            let claudeTokens = 6000
            let huggingFaceTokens = 6500
            
            let maxTokens = provider == .openAI ? openAITokens :
                            provider == .claude ? claudeTokens : huggingFaceTokens
            
            return (maxTokens, "Write a detailed story around 3000-4000 words. Include rich character development, vivid setting details, and a more complex narrative arc.")
            
        default:
            // Default to Medium
            let openAITokens = 3000
            let claudeTokens = 3500
            let huggingFaceTokens = 4000
            
            let maxTokens = provider == .openAI ? openAITokens :
                            provider == .claude ? claudeTokens : huggingFaceTokens
                            
            return (maxTokens, "Write a moderately detailed story around 1500-2000 words. Include character development and setting details.")
        }
    }
    
    private func getStylePrompt(_ style: String) -> String {
        switch style {
        case "Dark & Gritty Drama":
            return """
            A brutal, intense historical drama set in a ruthless world of power struggles, betrayals, and survival. Think **Game of Thrones, Peaky Blinders, or Gangs of New York**.
            The protagonist is thrust into a world where loyalty is a fleeting concept, and violence is often the only language spoken. Every choice has dire consequences.
            Expect **moral ambiguity, harsh realities, and visceral storytelling**.
            """
        case "Epic & Mythic":
            return """
            A grand, poetic, and sweeping mythic tale—a story that feels larger than life. Think **Gladiator, Troy, or The Last Kingdom**.
            The protagonist is **destined for greatness** (or tragedy), their life woven into the fabric of history itself. The narrative is **heroic, legendary, and deeply symbolic**, evoking the grandeur of ancient myths and timeless fables.
            Expect **epic battles, prophecies, and a touch of poetic destiny**.
            """
        case "Romantic & Tragic":
            return """
            A deeply romantic and tragic historical drama, steeped in **passion, longing, and fate**. Think **Romeo & Juliet, Titanic, or Moulin Rouge**.
            Love is intense, **forbidden, or doomed from the start**. The protagonist is caught in the grip of an emotional storm, where the heart's desires collide with the harshness of reality.
            Expect **sweeping emotions, tragic sacrifices, and the devastating beauty of love lost to time**.
            """
        case "Adventure & Survival":
            return """
            A fast-paced, high-stakes survival adventure set in a time of **chaos and danger**. Think **The Revenant, Apocalypto, or 1917**.
            The protagonist is on the run, fighting for survival, or embarking on a **perilous quest** through uncharted lands. They must **outwit, outfight, and endure** whatever the world throws at them.
            Expect **relentless action, visceral struggle, and a relentless fight for survival**.
            """
        case "Philosophical & Reflective":
            return """
            A deeply **introspective and philosophical** historical drama, where the protagonist grapples with **fate, morality, and the meaning of existence**. Think **The Last Temptation of Christ, The Seventh Seal, or A Hidden Life**.
            The story unfolds as an **inner journey** as much as an external one, questioning **free will, destiny, and the weight of past choices**.
            Expect **haunting dilemmas, poetic reflections, and moments of profound realization**.
            """
        case "Children's Story":
            return """
            A **heartwarming children's fable** where the characters are turned into **animals** that reflect their personalities.
            The story should be **gentle, fun, and engaging** for young minds, with a clear lesson about friendship, bravery, or discovery.
            - **Think classic fables like The Lion King, Charlotte's Web, or Winnie the Pooh**.
            - **Replace dark elements with lighthearted adventure.**
            - Use **talking animals, magical forests, and playful storytelling**.
            - **No astrology terms, no violence, no adult themes.**
            """
        default:
            return "A historical story deeply grounded in realism and emotion."
        }
    }
    
    private func createProviderSpecificPrompt(
        southNodeInfo: String,
        firstName: String,
        gender: String,
        selectedTimePeriod: String,
        stylePrompt: String,
        lengthInstruction: String,
        maxTokens: Int
    ) -> (Any, Int) {
        switch provider {
        case .openAI:
            // Format for ChatGPT/GPT-4
            let messages: [[String: String]] = [
                ["role": "system", "content": """
                You are a masterful historical storyteller. You create **dark, immersive, R-rated past-life stories** that feel like a **prestige drama series or a historical epic in this style:    - **Style:** \(stylePrompt)
                
                **Length guidance:**
                \(lengthInstruction)
                
                **The setting must be:**
                - **\(selectedTimePeriod)**
                The story must be **cinematic, character-driven, and grounded in a rich historical setting MAKE THE STORY HISTORICALLY ACCURATE ESPECIALLY IN REGARDS TO GENDER.** It should be gripping—filled with tension, moral dilemmas, and raw human emotion.
                
                **The tone should be mature, visceral, and unapologetically real.** Think of stories that belong in a high-stakes world of war, power, betrayal, survival, forbidden love, ambition, etc.
                
                No astrology terms. The reader does not know astrology. **Transform the astrological data into a fully immersive, character-driven past-life story.**
                
                **Important Guidelines:**
                - Do not use astrological terms or talk about past-life regression.
                - Do not explain symbolism—show it through the story.
                - The writing should be dark, tense, and filled with emotional weight.
                - Avoid anything "soft" or "mystical." This is **historical fiction, not fantasy**.
                - **Lean into R-rated drama:** sex, violence, betrayal, survival, and moral dilemmas WHEN INDICATED BY SYMBOLISM.
                - **NO SUBHEADERS**
                - **End the story without explaining it—let the reader feel it. If appropriate, close with an ambiguous or haunting final line.**
                """
                ],
                ["role": "user", "content": """
                The main character's name is **\(firstName)**. They are **\(gender)**. Their story must feel **real**—as if they lived and breathed in another time.
                
                Here is a structured past-life theme derived from an astrological chart:
                
                **Past-Life Themes:**
                \(southNodeInfo)
                """
                ]
            ]
            return (messages, maxTokens)
            
        case .claude:
            // Format for Claude API
            let systemPrompt = """
            You are a masterful historical storyteller. You create **dark, immersive, R-rated past-life stories** that feel like a **prestige drama series or a historical epic in this style:    - **Style:** \(stylePrompt)
            
            **Length guidance:**
            \(lengthInstruction)
            
            **The setting must be:**
            - **\(selectedTimePeriod)**
            The story must be **cinematic, character-driven, and grounded in a rich historical setting MAKE THE STORY HISTORICALLY ACCURATE ESPECIALLY IN REGARDS TO GENDER.** It should be gripping—filled with tension, moral dilemmas, and raw human emotion.
            
            **The tone should be mature, visceral, and unapologetically real.** Think of stories that belong in a high-stakes world of war, power, betrayal, survival, forbidden love, ambition, etc.
            
            No astrology terms. The reader does not know astrology. **Transform the astrological data into a fully immersive, character-driven past-life story.**
            
            **Important Guidelines:**
            - Do not use astrological terms or talk about past-life regression.
            - Do not explain symbolism—show it through the story.
            - The writing should be dark, tense, and filled with emotional weight.
            - Avoid anything "soft" or "mystical." This is **historical fiction, not fantasy**.
            - **Lean into R-rated drama:** sex, violence, betrayal, survival, and moral dilemmas WHEN INDICATED BY SYMBOLISM.
            - **NO SUBHEADERS**
            - **End the story without explaining it—let the reader feel it. If appropriate, close with an ambiguous or haunting final line.**
            """
            
            let userMessage = """
            The main character's name is **\(firstName)**. They are **\(gender)**. Their story must feel **real**—as if they lived and breathed in another time.
            
            Here is a structured past-life theme derived from an astrological chart:
            
            **Past-Life Themes:**
            \(southNodeInfo)
            """
            
            return ((systemPrompt, userMessage), maxTokens)
            
        case .huggingFace:
            // Format for Hugging Face Mistral model
            let prompt = """
            <s>[INST]
            You are a masterful historical storyteller. Create a past-life story with these guidelines:

            Style: \(stylePrompt)

            Setting: \(selectedTimePeriod)
            
            Length: \(lengthInstruction)

            The story must be cinematic, character-driven, and grounded in a rich historical setting. It should be historically accurate (especially regarding gender roles) and filled with tension, moral dilemmas, and raw human emotion.

            The tone should be mature, visceral, and unapologetically real. Do not use astrological terms or talk about past-life regression - transform the astrological data into a fully immersive story.

            Important guidelines:
            - Do not use astrological terms
            - Do not explain symbolism—show it through the story
            - The writing should be dark, tense, and filled with emotional weight
            - Avoid anything "soft" or "mystical" - this is historical fiction, not fantasy
            - No subheadings
            - End the story without explaining it - let the reader feel it
            
            The main character's name is **\(firstName)**. They are \(gender).

            Here are the past-life themes to incorporate:
            \(southNodeInfo)
            [/INST]
            """
            
            return (prompt, maxTokens)
        }
    }
    
    // MARK: - API Requests
    
    private func sendOpenAIRequest(prompt: Any, maxTokens: Int, completion: @escaping (Result<String, SouthNodeStoryError>) -> Void) {
        guard let messages = prompt as? [[String: String]] else {
            completion(.failure(.apiError("Invalid prompt format for OpenAI", nil)))
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare parameters
        let parameters: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": 0.7
        ]
        
        // Convert parameters to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(.apiError("Failed to serialize request: \(error.localizedDescription)", nil)))
            return
        }
        
        // Perform the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.apiError("No data received", nil)))
                return
            }
            
            // Process response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(.decodingError))
                }
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    private func sendClaudeRequest(prompt: Any, maxTokens: Int, completion: @escaping (Result<String, SouthNodeStoryError>) -> Void) {
        guard let (systemPrompt, userMessage) = prompt as? (String, String) else {
            completion(.failure(.apiError("Invalid prompt format for Claude", nil)))
            return
        }
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create request dictionary
        let requestDict: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": userMessage
                        ]
                    ]
                ]
            ]
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestDict) else {
            completion(.failure(.apiError("Failed to create JSON data", nil)))
            return
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.timeoutInterval = 60.0
        
        // Set headers according to Anthropic API documentation
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.apiError("No data received", nil)))
                return
            }
            
            do {
                // Try to extract content from the Claude response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = json["content"] as? [[String: Any]] {
                    
                    let texts = content.compactMap { item -> String? in
                        if let type = item["type"] as? String, type == "text",
                           let text = item["text"] as? String {
                            return text
                        }
                        return nil
                    }.joined()
                    
                    if !texts.isEmpty {
                        completion(.success(texts))
                        return
                    }
                }
                
                completion(.failure(.decodingError))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    private func sendHuggingFaceRequest(prompt: Any, maxTokens: Int, completion: @escaping (Result<String, SouthNodeStoryError>) -> Void) {
        guard let promptString = prompt as? String else {
            completion(.failure(.apiError("Invalid prompt format for Hugging Face", nil)))
            return
        }
        
        guard let url = URL(string: "https://api-inference.huggingface.co/models/\(model)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Create request parameters
        let parameters: [String: Any] = [
            "inputs": promptString,
            "parameters": [
                "max_new_tokens": maxTokens,
                "temperature": 0.7,
                "top_p": 0.95,
                "do_sample": true,
                "return_full_text": false
            ]
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(.apiError("Failed to create JSON data", nil)))
            return
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.apiError("No data received", nil)))
                return
            }
            
            do {
                // Check for array response format (most likely)
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let firstResult = jsonArray.first,
                   let generatedText = firstResult["generated_text"] as? String {
                    
                    completion(.success(generatedText))
                    return
                }
                
                // Try single object format
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check for error
                    if let error = json["error"] as? String {
                        if error.contains("is currently loading") {
                            completion(.failure(.modelLoading))
                        } else {
                            completion(.failure(.apiError(error, nil)))
                        }
                        return
                    }
                    
                    // Try to extract generated text
                    if let generatedText = json["generated_text"] as? String {
                        completion(.success(generatedText))
                        return
                    }
                }
                
                completion(.failure(.decodingError))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
}

// MARK: - SwiftEphemeris Extensions
import UIKit
import FirebaseAnalytics

import UIKit
import FirebaseAnalytics

class SouthNodeStoryViewController: UIViewController {
    var chartCake: ChartCake!
    weak var lilaViewController: MyAgentChatController?
    
    // MARK: - Properties
    
    private var selectedGender: String = "Male"
    private var selectedTimePeriod: String = "Random"
    private var selectedStyle: String = "Dark & Gritty Drama"
    private var selectedLength: String = "Medium" // Default length
    private var selectedProvider: SouthNodeStorytellerService.AIProvider = .claude // Default provider
    private var customTimePeriod: String? // For custom time period entries
    private var generatedStory: String? // Store the generated story
    
    // Service providers with API keys
    private let openAIApiKey = APIKeys.openAI
    private let claudeApiKey = APIKeys.anthropic
    private let huggingFaceApiKey = APIKeys.huggingFace
    
    // Lazy initialize the service provider based on selected provider
    private lazy var storyService: SouthNodeStorytellerService = {
        switch selectedProvider {
        case .openAI:
            return SouthNodeStorytellerService(chartCake: chartCake, apiKey: openAIApiKey, provider: .openAI)
        case .claude:
            return SouthNodeStorytellerService(chartCake: chartCake, apiKey: claudeApiKey, provider: .claude)
        case .huggingFace:
            return SouthNodeStorytellerService(chartCake: chartCake, apiKey: huggingFaceApiKey, provider: .huggingFace)
        }
    }()
    
    // Data options - matching the service implementation
    private let timePeriodOptions = [
        // Classical & Ancient Civilizations
        "Random",
        "Custom Time Period...",
        "Ancient Egypt",
        "Mesopotamia",
        "Ancient Greece",
        "Ancient Rome",
        "Persian Empire",
        "Ancient China",
        "Mesoamerica (Aztec, Maya, Olmec, Inca)",
        "Indus Valley Civilization",
        "African Kingdoms (Mali, Zulu, Kush, Aksum)",
        
        // Medieval & Feudal Societies
        "Medieval Europe",
        "Viking Age",
        "Byzantine Empire",
        "Mongol Empire",
        "Islamic Golden Age",
        "Feudal Japan (Samurai & Shogunate)",
        
        // Renaissance & Age of Exploration
        "Renaissance Italy",
        "Ottoman Empire",
        "Victorian England",
        "Spanish Conquest of the Americas",
        "Age of Exploration (1400s-1600s)",
        "French Revolution & Napoleonic Era",
        "Elizabethan England",
        
        // Industrial Revolution & Colonialism
        "Industrial Revolution",
        "Antebellum South",
        "American Wild West",
        "Russian Empire",
        "British Raj (Colonial India)",
        
        // Wars & Global Conflict
        "World War I",
        "Roaring Twenties & Prohibition",
        "World War II",
    ]
    
    private let storyStyleOptions = [
        "Dark & Gritty Drama",
        "Epic & Mythic",
        "Romantic & Tragic",
        "Adventure & Survival",
        "Philosophical & Reflective",
        "Children's Story"
    ]
    
    private let lengthOptions = ["Short", "Medium", "Long"]
    
    private let genderOptions = ["Male", "Female"]
    
    // MARK: - UI Elements - Configuration Panel
    
    private let configScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let configContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "South Node Story"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var genderLabel: UILabel = {
        let label = UILabel()
        label.text = "Character Gender:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var genderSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: genderOptions)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var timePeriodLabel: UILabel = {
        let label = UILabel()
        label.text = "Historical Era:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var timePeriodPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var customTimePeriodField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a custom time period..."
        textField.borderStyle = .roundedRect
        textField.isHidden = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var styleLabel: UILabel = {
        let label = UILabel()
        label.text = "Story Style:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var styleSegmentedControl: UISegmentedControl = {
        let styles = ["Dark", "Epic", "Romantic", "Adventure", "Reflective", "Children's"]
        let control = UISegmentedControl(items: styles)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var lengthLabel: UILabel = {
        let label = UILabel()
        label.text = "Story Length:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var lengthSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: lengthOptions)
        control.selectedSegmentIndex = 1 // Medium is default
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var providerLabel: UILabel = {
        let label = UILabel()
        label.text = "AI Provider:"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var providerSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["GPT-4o", "Claude", "Mistral"])
        control.selectedSegmentIndex = 1 // Claude is default
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate Story", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - UI Elements - Storybook Interface
    
    private let storyView = UIView()
    private let storyScrollView = UIScrollView()
    private let storyContentView = UIView()
    
    private lazy var storyTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont(name: "Georgia", size: 18) // More booklike font
        textView.textAlignment = .left
        textView.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 1.0) // Parchment-like color
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.brown.withAlphaComponent(0.3).cgColor
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = .black
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 2, height: 2)
        textView.layer.shadowOpacity = 0.1
        textView.layer.shadowRadius = 4
        return textView
    }()
    // Add to setupStoryView method where you create storyTextView

    private lazy var storyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your South Node Story"
        label.font = UIFont(name: "Georgia-Bold", size: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var storyInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Georgia-Italic", size: 14)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = .systemBlue
        button.isHidden = true // Initially hidden until we have a story
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var askLilaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ask Lila About This Story", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        button.tintColor = .systemPurple
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.isHidden = true // Initially hidden until we have a story
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var backToSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back to Settings", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .systemBlue
        button.isHidden = true // Initially hidden
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var providerInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Powered by Claude"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupActions()
        setupKeyboardDismissal()
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        // Set title
        title = "South Node Story"
        
        // Add navigation item to dismiss
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissView)
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add configuration panel first
        setupConfigPanel()
        
        // Initialize storybook view (initially hidden)
        setupStoryView()
        storyView.isHidden = true
        
        // Set initial state
        updateTimePeriodFieldVisibility()
    }
    
    private func setupConfigPanel() {
        view.addSubview(configScrollView)
        configScrollView.addSubview(configContentView)
        
        // Add UI elements to configContentView
        configContentView.addSubview(titleLabel)
        
        configContentView.addSubview(genderLabel)
        configContentView.addSubview(genderSegmentedControl)
        
        configContentView.addSubview(timePeriodLabel)
        configContentView.addSubview(timePeriodPicker)
        configContentView.addSubview(customTimePeriodField)
        
        configContentView.addSubview(styleLabel)
        configContentView.addSubview(styleSegmentedControl)
        
        configContentView.addSubview(lengthLabel)
        configContentView.addSubview(lengthSegmentedControl)
        
        configContentView.addSubview(providerLabel)
        configContentView.addSubview(providerSegmentedControl)
        
        configContentView.addSubview(generateButton)
        configContentView.addSubview(activityIndicator)
        configContentView.addSubview(providerInfoLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // ScrollView constraints
            configScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            configScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            configScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            configScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView constraints - same width as scrollView
            configContentView.topAnchor.constraint(equalTo: configScrollView.topAnchor),
            configContentView.leadingAnchor.constraint(equalTo: configScrollView.leadingAnchor),
            configContentView.trailingAnchor.constraint(equalTo: configScrollView.trailingAnchor),
            configContentView.bottomAnchor.constraint(equalTo: configScrollView.bottomAnchor),
            configContentView.widthAnchor.constraint(equalTo: configScrollView.widthAnchor),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: configContentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Gender section
            genderLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            genderLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            genderLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            genderSegmentedControl.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 8),
            genderSegmentedControl.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            genderSegmentedControl.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Time Period section
            timePeriodLabel.topAnchor.constraint(equalTo: genderSegmentedControl.bottomAnchor, constant: 16),
            timePeriodLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            timePeriodLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            timePeriodPicker.topAnchor.constraint(equalTo: timePeriodLabel.bottomAnchor, constant: 8),
            timePeriodPicker.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            timePeriodPicker.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            timePeriodPicker.heightAnchor.constraint(equalToConstant: 120),
            
            customTimePeriodField.topAnchor.constraint(equalTo: timePeriodPicker.bottomAnchor, constant: 8),
            customTimePeriodField.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            customTimePeriodField.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Style section
            styleLabel.topAnchor.constraint(equalTo: customTimePeriodField.bottomAnchor, constant: 16),
            styleLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            styleLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            styleSegmentedControl.topAnchor.constraint(equalTo: styleLabel.bottomAnchor, constant: 8),
            styleSegmentedControl.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            styleSegmentedControl.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Length section
            lengthLabel.topAnchor.constraint(equalTo: styleSegmentedControl.bottomAnchor, constant: 16),
            lengthLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            lengthLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            lengthSegmentedControl.topAnchor.constraint(equalTo: lengthLabel.bottomAnchor, constant: 8),
            lengthSegmentedControl.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            lengthSegmentedControl.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Provider section
            providerLabel.topAnchor.constraint(equalTo: lengthSegmentedControl.bottomAnchor, constant: 16),
            providerLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            providerLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            providerSegmentedControl.topAnchor.constraint(equalTo: providerLabel.bottomAnchor, constant: 8),
            providerSegmentedControl.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            providerSegmentedControl.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Provider info label
            providerInfoLabel.topAnchor.constraint(equalTo: providerSegmentedControl.bottomAnchor, constant: 16),
            providerInfoLabel.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            providerInfoLabel.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            
            // Generate button
            generateButton.topAnchor.constraint(equalTo: providerInfoLabel.bottomAnchor, constant: 20),
            generateButton.leadingAnchor.constraint(equalTo: configContentView.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: configContentView.trailingAnchor, constant: -20),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.bottomAnchor.constraint(equalTo: configContentView.bottomAnchor, constant: -20),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupStoryView() {
        view.addSubview(storyView)
        storyView.translatesAutoresizingMaskIntoConstraints = false

        storyView.addSubview(storyScrollView)
        storyScrollView.translatesAutoresizingMaskIntoConstraints = false
        storyScrollView.isScrollEnabled = true

        storyScrollView.addSubview(storyContentView)
        storyContentView.translatesAutoresizingMaskIntoConstraints = false

        storyContentView.addSubview(storyTitleLabel)
        storyContentView.addSubview(storyInfoLabel)
        storyContentView.addSubview(storyTextView)
        storyContentView.addSubview(shareButton)
        storyContentView.addSubview(askLilaButton)
        storyContentView.addSubview(backToSettingsButton)

        // ✨ Make the text view expand to fit content instead of scrolling inside itself
        storyTextView.isScrollEnabled = false
        storyTextView.textColor = .black

        NSLayoutConstraint.activate([
            // Story view (full screen)
            storyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            storyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            storyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            storyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Scroll view fills the story view
            storyScrollView.topAnchor.constraint(equalTo: storyView.topAnchor),
            storyScrollView.leadingAnchor.constraint(equalTo: storyView.leadingAnchor),
            storyScrollView.trailingAnchor.constraint(equalTo: storyView.trailingAnchor),
            storyScrollView.bottomAnchor.constraint(equalTo: storyView.bottomAnchor),

            // Content inside scroll view
            storyContentView.topAnchor.constraint(equalTo: storyScrollView.topAnchor),
            storyContentView.leadingAnchor.constraint(equalTo: storyScrollView.leadingAnchor),
            storyContentView.trailingAnchor.constraint(equalTo: storyScrollView.trailingAnchor),
            storyContentView.bottomAnchor.constraint(equalTo: storyScrollView.bottomAnchor),
            storyContentView.widthAnchor.constraint(equalTo: storyScrollView.widthAnchor),

            // Title
            storyTitleLabel.topAnchor.constraint(equalTo: storyContentView.topAnchor, constant: 20),
            storyTitleLabel.leadingAnchor.constraint(equalTo: storyContentView.leadingAnchor, constant: 20),
            storyTitleLabel.trailingAnchor.constraint(equalTo: storyContentView.trailingAnchor, constant: -20),

            // Info
            storyInfoLabel.topAnchor.constraint(equalTo: storyTitleLabel.bottomAnchor, constant: 8),
            storyInfoLabel.leadingAnchor.constraint(equalTo: storyContentView.leadingAnchor, constant: 20),
            storyInfoLabel.trailingAnchor.constraint(equalTo: storyContentView.trailingAnchor, constant: -20),

            // Share button
            shareButton.topAnchor.constraint(equalTo: storyInfoLabel.bottomAnchor, constant: 12),
            shareButton.trailingAnchor.constraint(equalTo: storyContentView.trailingAnchor, constant: -20),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),

            // 🌿 Expanded story text (no height constraint, just let it flow)
            storyTextView.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 8),
            storyTextView.leadingAnchor.constraint(equalTo: storyContentView.leadingAnchor, constant: 20),
            storyTextView.trailingAnchor.constraint(equalTo: storyContentView.trailingAnchor, constant: -20),

            // Ask Lila button
            askLilaButton.topAnchor.constraint(equalTo: storyTextView.bottomAnchor, constant: 20),
            askLilaButton.centerXAnchor.constraint(equalTo: storyContentView.centerXAnchor),

            // Back to settings button
            backToSettingsButton.topAnchor.constraint(equalTo: askLilaButton.bottomAnchor, constant: 16),
            backToSettingsButton.centerXAnchor.constraint(equalTo: storyContentView.centerXAnchor),
            backToSettingsButton.bottomAnchor.constraint(equalTo: storyContentView.bottomAnchor, constant: -20)
        ])
    }

    // Also add this method to adjust the content size after the story is loaded
    private func adjustScrollViewContentSize() {
        // Call this after setting the text to storyTextView
        DispatchQueue.main.async {
            // Calculate the content size based on the actual content
            let textHeight = self.storyTextView.sizeThatFits(
                CGSize(width: self.storyTextView.frame.width, height: CGFloat.greatestFiniteMagnitude)
            ).height
            
            // Update height constraint to fit content
            for constraint in self.storyTextView.constraints {
                if constraint.firstAttribute == .height {
                    constraint.constant = max(600, textHeight)
                    break
                }
            }
            
            // Force layout update
            self.view.layoutIfNeeded()
        }
    }
    private func setupDelegates() {
        timePeriodPicker.delegate = self
        timePeriodPicker.dataSource = self
        customTimePeriodField.delegate = self
    }
    
    private func setupActions() {
        generateButton.addTarget(self, action: #selector(generateStory), for: .touchUpInside)
        genderSegmentedControl.addTarget(self, action: #selector(genderChanged), for: .valueChanged)
        styleSegmentedControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        lengthSegmentedControl.addTarget(self, action: #selector(lengthChanged), for: .valueChanged)
        providerSegmentedControl.addTarget(self, action: #selector(providerChanged), for: .valueChanged)
        shareButton.addTarget(self, action: #selector(shareStory), for: .touchUpInside)
        askLilaButton.addTarget(self, action: #selector(askLilaAboutStory), for: .touchUpInside)
        backToSettingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
    }
    @objc private func showSettings() {
        switchToConfigView()
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
    
    // MARK: - UI Updates
    
    private func updateTimePeriodFieldVisibility() {
        // Show text field if "Custom Time Period" is selected
        let isCustomSelected = selectedTimePeriod == "Custom Time Period..."
        customTimePeriodField.isHidden = !isCustomSelected
    }
    
    private func switchToStoryView() {
        print("[DEBUG] Starting switchToStoryView")
        print("[DEBUG] Before transition - configScrollView.isHidden: \(configScrollView.isHidden)")
        print("[DEBUG] Before transition - storyView.isHidden: \(storyView.isHidden)")
        
        UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
              self.configScrollView.isHidden = true
              self.storyView.isHidden = false
          }, completion: { _ in
              // Add this after the transition completes
              self.storyScrollView.contentSize = CGSize(
                  width: self.storyContentView.frame.width,
                  height: self.storyTextView.frame.maxY + 50
              )
          })
      }
    
    private func switchToConfigView() {
        UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.storyView.isHidden = true
            self.configScrollView.isHidden = false
        })
    }
    
    // MARK: - Actions
    
    @objc private func genderChanged() {
        selectedGender = genderOptions[genderSegmentedControl.selectedSegmentIndex]
    }
    
    @objc private func styleChanged() {
        selectedStyle = storyStyleOptions[styleSegmentedControl.selectedSegmentIndex]
    }
    
    @objc private func lengthChanged() {
        selectedLength = lengthOptions[lengthSegmentedControl.selectedSegmentIndex]
    }
    
    @objc private func providerChanged() {
        switch providerSegmentedControl.selectedSegmentIndex {
        case 0:
            selectedProvider = .openAI
            providerInfoLabel.text = "Powered by GPT-4o"
        case 1:
            selectedProvider = .claude
            providerInfoLabel.text = "Powered by Claude"
        case 2:
            selectedProvider = .huggingFace
            providerInfoLabel.text = "Powered by Mistral"
        default:
            selectedProvider = .claude
            providerInfoLabel.text = "Powered by Claude"
        }
        
        // Recreate service with new provider
        storyService = SouthNodeStorytellerService(
            chartCake: chartCake,
            apiKey: selectedProvider == .openAI ? openAIApiKey :
                selectedProvider == .claude ? claudeApiKey : huggingFaceApiKey,
            provider: selectedProvider
        )
    }
    
    @objc private func shareStory() {
        guard let storyText = generatedStory, !storyText.isEmpty else { return }
        
        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [storyText],
            applicationActivities: nil
        )
        
        // Present the controller
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    // Fixed askLilaAboutStory method with Result type handling
    @objc private func askLilaAboutStory() {
        guard let story = generatedStory else { return }
        
        // Set up a nice dialogue to return to Lila with the story details
        let storyDetails = """
        Time Period: \(selectedTimePeriod == "Custom Time Period..." ? (customTimePeriod ?? "Custom") : selectedTimePeriod)
        Style: \(selectedStyle)
        Character Gender: \(selectedGender)
        Length: \(selectedLength)
        AI Provider: \(providerInfoLabel.text?.replacingOccurrences(of: "Powered by ", with: "") ?? "Unknown")
        """
        
        // Dismiss this view controller
        dismiss(animated: true) { [weak self] in
            // Ask Lila about the story
            if let lilaVC = self?.lilaViewController {
                let message = "Can you tell me more about the South Node story you just created for me? Why did you choose these themes and setting based on my chart?"
                lilaVC.addSystemMessage("🔮 I see you're curious about the South Node story. Here's what I can tell you about why this story emerged from your chart...")
                
                // Create a detailed explanation from Lila
                let currentService = AstrologyServiceManager.shared.currentService
                
                let prompt = """
                The user is asking about a South Node story generated from their chart. They want to understand the astrological significance and symbolism behind it.
                
                Story settings:
                \(storyDetails)
                
                Briefly explain how their South Node placement in their chart relates to this story, focusing on:
                1. How their South Node sign and house influenced the themes
                2. How any aspects to the South Node shaped character dynamics
                3. Why this particular time period and style reflect their karmic patterns
                4. What lessons or growth opportunities this story might symbolize for them
                
                Keep the explanation warm, insightful and not too technical - connect it to their personal journey.
                """
                
                let chartToUse = lilaVC.transitChartCake ?? lilaVC.chartCake
                
                // Fixed: Handle the Result type properly
                currentService.generateResponse(
                    prompt: prompt,
                    chartCake: chartToUse,
                    otherChart: lilaVC.otherChart,
                    transitDate: lilaVC.transitChartCake?.transits.transitDate
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let responseText):
                            lilaVC.addSystemMessage(responseText)
                        case .failure:
                            lilaVC.addSystemMessage("I'm sorry, I couldn't generate an explanation for your story at the moment. The South Node story is based on your South Node placement in your chart, which indicates past-life patterns and karmic lessons you're working with in this lifetime.")
                        }
                    }
                }
            }
        }
    }
 
    
    @objc private func generateStory() {
        guard chartCake != nil else {
            print("[DEBUG] Error: Chart data is missing")
            storyTextView.text = "Error: Chart data is missing."
            return
        }

        // ✅ Check if the user has already generated a story today
        if !canGenerateNewStory() {
            if isUserPremium() {
                print("[DEBUG] Premium user - bypassing daily limit")
            } else {
                showPaywall() // ✅ Show YOUR paywall instead of an alert
                return
            }
        }

        // Check if custom time period is selected but not filled
        if selectedTimePeriod == "Custom Time Period..." && (customTimePeriod?.isEmpty ?? true) {
            let alert = UIAlertController(
                title: "Missing Time Period",
                message: "Please enter a custom time period or select one from the list.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Start loading
        activityIndicator.startAnimating()
        generateButton.isEnabled = false

        // ✅ Store the latest query timestamp in UserDefaults (Only for non-premium users)
        if !isUserPremium() {
            UserDefaults.standard.set(Date(), forKey: "lastSouthNodeStoryDate")
        }

        // The actual time period to use
        let timePeriodToUse = selectedTimePeriod == "Custom Time Period..." ? customTimePeriod! : selectedTimePeriod

        // Log parameters for debugging
        print("[DEBUG] Generating story with parameters:")
        print("[DEBUG] Gender: \(selectedGender)")
        print("[DEBUG] Time Period: \(timePeriodToUse)")
        print("[DEBUG] Style: \(selectedStyle)")
        print("[DEBUG] Length: \(selectedLength)")
        print("[DEBUG] Provider: \(providerInfoLabel.text ?? "Unknown")")

        // Log analytics event
        Analytics.logEvent("south_node_story_generated", parameters: [
            "provider": providerInfoLabel.text ?? "Unknown",
            "gender": selectedGender,
            "time_period": timePeriodToUse,
            "style": selectedStyle,
            "length": selectedLength
        ])

        // Prepare storybook view
        storyTitleLabel.text = selectedStyle == "Children's Story" ? "A South Node Tale" : "A Past Life Journey"
        storyInfoLabel.text = "\(timePeriodToUse) • \(selectedStyle)"
        storyTextView.text = "Generating your story..."

        // Make the request with the proper parameters to match the service
        storyService.generateSouthNodeStory(
            gender: selectedGender,
            timePeriod: timePeriodToUse,
            style: selectedStyle,
            length: selectedLength
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.generateButton.isEnabled = true

                switch result {
                case .success(let story):
                    print("[DEBUG] Story generated successfully!")
                    print("[DEBUG] Story length: \(story.count) characters")
                    print("[DEBUG] First 100 characters: \(story.prefix(100))")

                    // Store the generated story
                    self?.generatedStory = story

                    // Format the story with a nice first letter
                    let formattedStory = self?.formatStoryText(story) ?? story

                    // Update UI
                    self?.storyTextView.text = formattedStory
                    self?.shareButton.isHidden = false
                    self?.askLilaButton.isHidden = false
                    self?.backToSettingsButton.isHidden = false

                    // Adjust content size based on actual text content
                    self?.adjustScrollViewContentSize()

                    // Switch to storybook view
                    self?.switchToStoryView()
                    print("[DEBUG] Is storyView hidden after switch: \(self?.storyView.isHidden ?? true)")

                case .failure(let error):
                    print("[DEBUG] Error generating story: \(error)")
                    print("[DEBUG] Error description: \(error.localizedDescription)")

                    let alertController = UIAlertController(
                        title: "Story Generation Failed",
                        message: "We couldn't generate your story: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )

                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }

    // ✅ Helper function to check if the user can generate a new story today
    private func canGenerateNewStory() -> Bool {
        let lastQueryDate = UserDefaults.standard.object(forKey: "lastSouthNodeStoryDate") as? Date ?? Date.distantPast
        return !Calendar.current.isDateInToday(lastQueryDate) // Returns true if it's a new day
    }

    // ✅ Check if the user is premium (Replace with real check)
    private func isUserPremium() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser") // Replace with real premium check
    }

    // ✅ Use your existing paywall logic
    private func showPaywall() {
        let alert = UIAlertController(
            title: "Upgrade to Unlimited Access",
            message: "You’ve reached your daily limit of free queries. Upgrade to Lila Premium for unlimited insights.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Subscribe", style: .default) { _ in
            SubscriptionManager.shared.purchaseSubscription() // ✅ Calls your existing subscription logic
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func formatStoryText(_ text: String) -> String {
        // For now, just return the original text
        // This can be enhanced later with styled text if desired
        return text
    }
}
    // MARK: - UIPickerViewDelegate & UIPickerViewDataSource
    extension SouthNodeStoryViewController: UIPickerViewDelegate, UIPickerViewDataSource {
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return timePeriodOptions.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return timePeriodOptions[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selectedTimePeriod = timePeriodOptions[row]
            updateTimePeriodFieldVisibility()
        }
    }

    // MARK: - UITextFieldDelegate
    extension SouthNodeStoryViewController: UITextFieldDelegate {
        func textFieldDidEndEditing(_ textField: UITextField) {
            if textField == customTimePeriodField {
                customTimePeriod = textField.text
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

 
