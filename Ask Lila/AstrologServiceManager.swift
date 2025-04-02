

import Foundation
class AstrologyServiceManager {
    static let shared = AstrologyServiceManager()
    
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

// MARK: - AIServiceSelectorDelegate Protocol
protocol AIServiceSelectorDelegate: AnyObject {
    func didSelectAIService()
}

