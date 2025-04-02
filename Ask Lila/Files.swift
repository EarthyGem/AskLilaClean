import Foundation
import UIKit

var risingSignArray: [String: [String]] = [:]

func generateAstroSentence(strongestPlanet: String,
                           strongestPlanetSign: String,
                           sunSign: String,
                           moonSign: String,
                           risingSign: String, name: String) -> String {
    // Define arrays of arrays for adjectives and archetypes
    let adjectiveArrays: [String: [String]] = ["Aries": ["The Fiery", "The Bold", "The Courageous", "The Pioneering", "The Competitive", "The Passionate", "The Energetic", "The Active", "The Independant", "The Assertive", "The Militant", "The Combative", "The Commanding", "The Pushy", "The Lusty"],
                                               "Taurus": ["The Plodding", "The Peace Loving", "The Grounded", "The Steadfast", "The Dependable", "The Practical", "The Reliable", "The Possessive", "The Patient", "The Industrious", "The Conservative", "The Stubborn", "The Immovable"],
                                               "Gemini": ["The Witty", "The Versatile", "The Curious", "The Open-Minded", "The Perceptive", "The Chatty", "The Verbose", "The Thinking", "The Nervous", "The Mercurial", "The Changeable", "The Intellectual", "The Restless", "Informative", "Multi-tasking", "The Dexterous"],
                                               "Cancer": ["The Caring", "The Nurturing", "The Sensitive", "The Family Oriented", "The Protective", "The Shy", "The Emotional", "The Moody", "The Sympathetic", "The Timid", "The Receptive", "The Tenacious", "The Whimsical", "The Feeling", "The Impressionistic", "The Domestic", "The Kind"],
                                               "Leo": ["The Shining", "The Dignified", "The Warmhearted", "The Candid",  "Dominating","The Majestic", "The Strong", "The Impactful", "The Proud", "The Regal", "The Willful", "The Commanding"],
                                               "Virgo": ["The Analytical", "The Practical", "The Informative", "Instructive", "The Studious", "The Critical", "The Discriminating",  "The Knowledgeable","The Scientific"],
                                               "Libra": ["The Pleasing", "The Diplomatic", "The Harmonious", "The Sweet", "The Artistic", "The Peace Loving", "The Harmonizing", "The Appreciative", "The Social", "The Refined", "The Sympathetic", "The Affectionate", "The Polite", "The Courteous"],
                                               "Scorpio": ["The Intense", "The Deep", "The Dark", "The Resourceful", "The Desirous", "The Penetrating", "The Magnetic", "The Secretive", "The Brooding"],
                                               "Sagittarius": ["The Adventurous", "The Philosophical", "The Optimistic", "The Opinionated", "The Dogmatic", "The Religious", "The Well Travelled", "The Jovial", "The Outspoken", "The Faithful"],
                                               "Capricorn": ["The Ambitious", "The Disciplined", "The Responsible", "The Hardworking", "The Serious", "The Orderly", "The Practical", "The Cheap", "The Economical", "The Business-Minded", "The Industrious", "The Cunning", "The Cautious", "The Careful"],
                                               "Aquarius": ["The Eccentric", "The Innovative", "Independent", "The Futuristic", "The Rebellious", "The Freedom Loving", "The Individualistic", "The One-of-a-Kind", "The Genius", "The Independent", "The Progressive", "The Argumentative"],
                                               "Pisces": ["The Sensitive", "The Compassionate", "The Visionary", "The Imaginative", "The Spiritual", "The Other Worldly", "The Dreamy", "The Transcendent", "The Poetic", "The Idealistic", "The Mystical", "The Worrisome", "The Delusional", "The Confused"]]

    let planetArrays: [String: [String]] = [
        "Sun": [ "Creator", "Star", "Leader"],
        "Moon": ["Nurturer", "Comforter","Healer", "Caregiver", "Provider"],
        "Mercury": [ "Thinker","Storyteller","Messenger",
                     "Intellectual","Teacher"],
        "Venus": [ "Harmonizer", "Beautifier", "Connector", "Lover",
                  "Peacemaker" ],
        "Mars": ["Warrior", "Builder", "Protector","Pioneer","Fighter"],
        "Jupiter": ["Philosopher", "Explorer", "Benefactor", "Bestower of Blessings","Preacher"],
        "Saturn": ["Organizer", "Strategist", "Planner", "Security Provider"],
        "Uranus": [ "Awakener", "Renegade", "Innovator", "Change Agent",
                    "Disruptor"],
        "Neptune": ["Dreamer", "Visionary", "Idealist"],
        "Pluto": ["Transformer", "Alchemist", "Revealer"],
        "S.Node": ["Karma", "Karma", "Karma"],
        "Ascendant": ["Transformer", "Alchemist", "Revealer"],
        "Midheaven": ["Karma"]
    ]



    let risingSignArrays: [String: [String]] = signArrays.mapValues { attributes in
        attributes.map { attribute in
            if let firstChar = attribute.first, "aeiouAEIOU".contains(firstChar) {
                return "an \(attribute)"
            } else {
                return "a \(attribute)"
            }
        }
    }

    // Randomly select adjectives and archetypes from arrays
    let adjective = adjectiveArrays[strongestPlanetSign]?.randomElement() ?? "The"
    let planetArchetype = planetArrays[strongestPlanet]!.randomElement()!
    let sunArchetype = signArrays[sunSign]!.randomElement()!
    let moonArchetype = signArrays[moonSign]!.randomElement()!
    let risingArchetype = risingSignArrays[risingSign]!.randomElement()!

    // Construct and return sentence
    let sentence = "\(name) is \(adjective) \(planetArchetype), with the Spirit of the \(sunArchetype), and the soul of the \(moonArchetype), who acts like \(risingArchetype)."

    return sentence
}


func generateStrongestPlanet(strongestPlanet: String,
                           strongestPlanetSign: String, name: String) -> String {
    // Define arrays of arrays for adjectives and archetypes
    let adjectiveArrays: [String: [String]] = ["Aries": ["The Fiery", "The Bold", "The Courageous", "The Pioneering", "The Competitive", "The Passionate", "The Energetic", "The Active", "The Independant", "The Assertive", "The Militant", "The Combative", "The Commanding", "The Pushy", "The Lusty"],
                                               "Taurus": ["The Plodding", "The Peace Loving", "The Grounded", "The Steadfast", "The Dependable", "The Practical", "The Reliable", "The Possessive", "The Patient", "The Industrious", "The Conservative", "The Stubborn", "The Immovable"],
                                               "Gemini": ["The Witty", "The Versatile", "The Curious", "The Open-Minded", "The Perceptive", "The Chatty", "The Verbose", "The Thinking", "The Nervous", "The Mercurial", "The Changeable", "The Intellectual", "The Restless", "Informative", "Multi-tasking", "The Dexterous"],
                                               "Cancer": ["The Caring", "The Nurturing", "The Sensitive", "The Family Oriented", "The Protective", "The Shy", "The Emotional", "The Moody", "The Mediumistic", "The Sympathetic", "The Timid", "The Receptive", "The Adaptable", "The Whimsical", "The Tenacious", "The Impressionistic", "The Domestic", "The Kind", "The Dreamy"],
                                               "Leo": ["The Shining", "The Dignified", "The Warmhearted", "The Candid", "Forceful", "Dominating","The Majestic", "The Strong", "The Impactful", "The Proud", "The Regal", "The Willful", "The Commanding", "The Bossy"],
                                               "Virgo": ["The Analytical", "The Practical", "The Informative", "Instructive", "The Studious", "The Critical", "The Discriminating",  "The Knowledgeable","The Scientific", "The Mentally Alert", "The Ingenious"],
                                               "Libra": ["The Pleasing", "The Diplomatic", "The Harmonious", "The Sweet", "The Artistic", "The Peace Loving", "The Harmonizing", "The Appreciative", "The Social", "The Refined", "The Sympathetic", "The Affectionate", "The Polite", "The Courteous"],
                                               "Scorpio": ["The Intense", "The Deep", "The Dark", "The Resourceful", "The Desirous", "The Penetrating", "The Forceful", "The Magnetic", "The Secretive", "The Brooding", "The Determined"],
                                               "Sagittarius": ["The Adventurous", "The Philosophical", "The Optimistic", "The Opinionated", "The Dogmatic", "The Religious", "The Worldly", "The Jovial", "The Outspoken", "The Faithful"],
                                               "Capricorn": ["The Ambitious", "The Disciplined", "The Responsible", "The Hardworking", "The Serious", "The Orderly", "The Practical", "The Cheap", "The Economical", "The Business-Minded", "The Industrious", "The Cunning", "The Cautious", "The Careful"],
                                               "Aquarius": ["The Eccentric", "The Innovative", "Independent", "The Futuristic", "The Rebellious", "The Freedom Loving", "The Individualistic", "The One-of-a-Kind", "The Friendly", "The Genius", "The Independent", "The Progressive", "The Argumentative"],
                                               "Pisces": ["The Sensitive", "The Compassionate", "The Visionary", "The Imaginative", "The Spiritual", "The Other Worldly", "The Dreamy", "The Transcendent", "The Poetic", "The Idealistic", "The Mystical", "The Mediumistic", "The Sympathetic", "The Romantic", "The Worrisome", "The Delusional", "The Confused"]]

    let planetArrays: [String: [String]] = [
        "Sun": [ "Creator", "Star", "Leader"],
        "Moon": ["Nurturer", "Comforter","Healer", "Caregiver", "Provider"],
        "Mercury": [ "Thinker","Storyteller","Messenger",
                     "Intellectual","Teacher"],
        "Venus": [ "Harmonizer", "Beautifier", "Connector", "Lover",
                  "Peacemaker" ],
        "Mars": ["Warrior", "Builder", "Protector","Pioneer","Fighter"],
        "Jupiter": ["Philosopher", "Explorer", "Benefactor", "Bestower of Blessings","Preacher"],
        "Saturn": ["Organizer", "Strategist", "Planner", "Security Provider"],
        "Uranus": [ "Awakener", "Renegade", "Innovator", "Change Agent",
                    "Disruptor"],
        "Neptune": ["Dreamer", "Visionary", "Idealist"],
        "Pluto": ["Transformer", "Alchemist", "Revealer"],
        "S.Node": ["Karma", "Karma", "Karma"],
        "Ascendant": ["Transformer", "Alchemist", "Revealer"],
        "Midheaven": ["Karma"]
    ]

 
    let risingSignArrays: [String: [String]] = signArrays.mapValues { attributes in
        attributes.map { attribute in
            if let firstChar = attribute.first, "aeiouAEIOU".contains(firstChar) {
                return "an \(attribute)"
            } else {
                return "a \(attribute)"
            }
        }
    }

    // Randomly select adjectives and archetypes from arrays
    let adjective = adjectiveArrays[strongestPlanetSign]?.randomElement() ?? "The"
    let planetArchetype = planetArrays[strongestPlanet]!.randomElement()!
  

    // Construct and return sentence
    let sentence = "\(adjective) \(planetArchetype)"

    return sentence
}


func getAnimal(animal: String) -> String {
    
    return animal
}
let signArrays: [String: [String]] = ["Aries": ["Warrior", "Fighter", "Pioneer", "Athlete", "Builder", "Destroyer"],
                                      "Taurus": ["Farmer", "Collector", "Grounded Person", "\(getAnimal)"],
                                      "Gemini": [ "Commentator", "Scribe", "Teacher", "Adaptor", "Bookworm", "Communicator", "Curious One", "Educator", "Free Associator", "Information Junkie", "Intellectual", "Interviewer", "Jack-of-all-Trades", "Journalist", "Linguist", "Listener", "Messenger", "Mouthpiece", "Observer", "Questioner", "Raconteur", "Storyteller", "Student", "Thinker", "Translator", "Trickster", "Wordsmith", "Writer"],
                                      "Cancer": ["Caregiver", "Comforter", "Cook", "Feeler", "Guardian", "Healer", "Homebody", "Nester", "Nurse", "Nurturer", "Parent", "Protector", "Rememberer", "Sensitive One", "Sentimental One", "Supportive One", "Therapist"],
                                      "Leo": ["Aristocrat", "Champ", "Class Clown", "Comedian", "Creative", "Creator", "Diva", "Emcee", "Entertainer", "Force of Nature", "Gifted One", "Host", "Lion", "Performer", "Prima Donna", "Rock Star", "Artist", "Boss", "Celebrity", "Golden Child", "Icon", "Influencer", "Leader of the Pack",  "Powerhouse", "Royalty"],
                                      "Virgo": ["Servant", "Work in Progress", "Analyst", "Problem Solver", "Details Person", "Health Nut", "Purist", "Critic", "Practitioner", "Craftsperson", "Technician", "Librarian",  "Trainer", "Apprentice", "Coach", "Devotee", "Disciple", "Engineer", "Fixer", "Master-in-Training", "Mentor", "Perpetual Student", "Programmer",  "Self-Help Junkie"],
                                      "Libra": ["Peacemaker", "Diplomat", "Refiner", "Socialite", "Social Director", "Egalitarian", "Negotiator", "Matchmaker", "Artist", "Ambassador",  "Balancer", "Fashionista", "Connoisseur", "Beautifier", "Artist",  "Connoisseur", "Cosmopolitan", "Cultured One", "Decorator",  "Harmonizer", "Idealist", "Mediator", "Muse", "Social Butterfly", "Sophisticate", "Sweetheart", "Sympathizer", "Romanticizer",  "Adorer"],
                                      "Scorpio": ["Alchemist", "Brooder", "Confidante", "Dark One", "Deep Thinker", "Detective", "Excavator", "Extremist", "Goth", "Hospice Worker", "Hypnotist", "Intense One", "Lady of the Underworld", "Lord of the Underworld", "Occultist", "Penetrator", "Phoenix", "Provocateur", "Psychoanalyst", "Reformer", "Regenerist", "Revealer", "Secret-Keeper", "Shaman", "Sorcerer", "Survivor", "Taboo-Breaker", "Transformer", "Truth-Teller", "Undertaker", "Wounded Healer"],
                                      "Sagittarius": ["Traveler", "Philosopher", "Scholar", "Opinion Giver", "Risk-Taker", "Professional", "Seer", "Preacher", "Believer"],
                                      "Capricorn": ["Achiever", "Climber", "Grinder", "Boss", "Chief", "Consigliere", "Control Freak",  "Stoic", "Discipliner", "Executive", "Organizer", "Manifester", "Master",  "Old Soul", "Parent", "Planner", "Pragmatist", "Realist", "Rule-Follower", "Stoic", "Strategist", "Workaholic", "Taskmaster", "Traditionalist",  "Judge", "Authority"],
                                      "Aquarius": ["Anarchist", "Astrologer", "Awakener", "Contrarian", "Counterculturalist", "Dissenter", "Eccentric", "Entrepreneur", "Free Thinker", "Futurist", "Genius", "Groundbreaker", "Iconoclast", "Individualist", "Innovator", "Liberal", "Liberator", "Misfit", "Networker", "Nonconformist", "Outsider", "Radical", "Rebel", "Renegade", "Revolutionary", "Techie", "One of a Kind", "Agent of Change", "Disruptor", "Free Radical", "Inventor", "Maverick", "Outsider", "Astrologer", "Rebel with a Cause"],
                                      "Pisces": ["Artist", "Chameleon",  "Dreamer", "Empath", "Enchanter",  "Idealist",  "Master Actor", "Meditator", "Medium", "Muse", "Mystic",  "Poet",  "Psychic", "Shapeshifter", "Spiritualist", "Visionary",  "Yogi",  "Intuitive",   "Transcendentalist", "Utopian", "Visionary Artist"]]


import Foundation
import CoreLocation

var birthPlaceTimeZone: TimeZone?

// Dictionary of known locations
let knownLocations: [String: (latitude: Double, longitude: Double)] = [
    "Kesswill": (latitude: 47.5942, longitude: 9.3135),
    "BOLOTNOJE": (latitude: 55.6731, longitude: 84.3933),
    "BOLOTNOJE, Russia": (latitude: 55.6731, longitude: 84.3933),
    "Kiskunfelegyhaza, Hungary": (latitude: 46.7113, longitude: 19.8447),
    "Bolotnoye, Russia": (latitude: 55.6731, longitude: 84.3933),
    "Zundert, Netherlands": (latitude: 51.4716, longitude: 4.6558),
    "Quezon City, Philippines": (latitude: 14.6760, longitude: 121.0437) // Add Quezon City here
    // Add more known locations here
]

/// Function to handle geocoding a location name to latitude and longitude coordinates.
/// - Parameters:
///   - location: The name of the location (city, state, etc.).
///   - completion: Callback with the geocoded latitude and longitude.
///   - failure: Callback when geocoding fails with an error message.
func geocoding(location: String, completion: @escaping (_ latitude: Double, _ longitude: Double) -> Void, failure: @escaping (_ msg: String) -> Void) {
    // Check if the location is a known location
    if let coordinates = knownLocations[location] {
        completion(coordinates.latitude, coordinates.longitude)
        return
    }

    let geocoder = CLGeocoder()

    geocoder.geocodeAddressString(location) { (placemarks, error) in
        if let error = error as? CLError {
            print("Geocoding error: \(location.lowercased()) - \(error.localizedDescription)")
            switch error.code {
            case .geocodeFoundNoResult:
                failure("No results found for the location: \(location).")
            case .network:
                failure("Network error occurred. Please check your internet connection.")
            case .geocodeCanceled:
                failure("Geocoding request was canceled.")
            case .geocodeFoundPartialResult:
                failure("Partial results found. Try to be more specific for the location: \(location).")
            default:
                failure("Geocoding error: \(error.localizedDescription)")
            }
            return
        }

        guard let placemark = placemarks?.first,
              let location = placemark.location else {
            print("Failed to get location for: \(location.lowercased())")
            failure("Sorry, we can't get details for the place: \(location). Please check the spelling or try a more specific query.")
            return
        }

        birthPlaceTimeZone = placemark.timeZone
        completion(location.coordinate.latitude, location.coordinate.longitude)
    }
}

/// Function to get the timezone for a given latitude and longitude.
/// - Parameters:
///   - location: The coordinates of the location.
///   - completion: Callback with the found TimeZone.
func getTimeZone(location: CLLocationCoordinate2D, completion: @escaping ((TimeZone?) -> Void)) {
    let cllLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
    let geocoder = CLGeocoder()

    geocoder.reverseGeocodeLocation(cllLocation) { placemarks, error in
        if let error = error {
            print("Reverse geocoding error: \(error.localizedDescription)")
        } else {
            completion(placemarks?.first?.timeZone)
        }
    }
}

