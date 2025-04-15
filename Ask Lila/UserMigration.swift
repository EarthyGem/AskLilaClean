import Foundation
import FirebaseCore
import CoreData
import FirebaseFirestore
import FirebaseAuth

// Add this to your AppDelegate or SceneDelegate
class MigrationManager {
    static let shared = MigrationManager()
    private let db = Firestore.firestore()
    
    // Call this when user successfully logs in or app starts with existing user
    func checkAndMigrateCurrentUserIfNeeded(completion: @escaping (Bool) -> Void) {
        // Make sure we have an authenticated user
        guard let currentUser = Auth.auth().currentUser else {
            print("No authenticated user found, skipping migration check")
            completion(false)
            return
        }
        
        let userId = currentUser.uid
        print("Checking migration status for user: \(userId)")
        
        // Check if user exists in Firestore already
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Check if we have already migrated this user
                if document.data()?["migrationCompleted"] as? Bool == true {
                    print("User data already migrated to Firestore")
                    completion(true)
                    return
                }
            }
            
            // User doesn't exist in Firestore or migration not marked complete
            // Find and migrate the user's profile data from Core Data
            self.migrateUserProfileFromCoreData(userId: userId) { success in
                completion(success)
            }
        }
    }
    
    private func migrateUserProfileFromCoreData(userId: String, completion: @escaping (Bool) -> Void) {
        print("Starting migration for user: \(userId)")
        
        // Get Core Data context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Could not access AppDelegate")
            completion(false)
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Fetch UserProfileEntity for this specific user
        let fetchRequest: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uid == %@", userId)
        
        do {
            let profiles = try context.fetch(fetchRequest)
            print("Found \(profiles.count) profile(s) for user \(userId)")
            
            if let profile = profiles.first {
                // We found the profile, migrate it to Firestore
                migrateProfileToFirestore(profile: profile, userId: userId) { success in
                    completion(success)
                }
            } else {
                // No profile found, perhaps this is a new user?
                print("No Core Data profile found for user \(userId)")
                completion(false)
            }
            
        } catch {
            print("Error fetching user profile from Core Data: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    private func migrateProfileToFirestore(profile: UserProfileEntity, userId: String, completion: @escaping (Bool) -> Void) {
        // Convert profile to Firestore data
        var profileData = convertUserProfileToFirestoreData(profile)
        
        // Add migration metadata
        profileData["migrationCompleted"] = true
        profileData["migrationDate"] = Date()
        
        // Save to Firestore
        db.collection("users").document(userId).setData(profileData, merge: true) { error in
            if let error = error {
                print("Error saving profile to Firestore: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("Successfully migrated profile for user \(userId) to Firestore")
            
            // Save migration status to UserDefaults as well (belt and suspenders)
            UserDefaults.standard.set(true, forKey: "profileMigrated_\(userId)")
            
            completion(true)
        }
    }
    
    private func convertUserProfileToFirestoreData(_ userProfile: UserProfileEntity) -> [String: Any] {
        var profileData: [String: Any] = [
            "displayName": userProfile.displayName ?? "",
            "email": userProfile.email ?? "",
            "uid": userProfile.uid ?? UUID().uuidString,
            "migrationDate": Date(),
            "source": "CoreData Migration"
        ]
        
        // Extract astrological data from UserProfileEntity
        profileData["sun"] = userProfile.sun ?? ""
        profileData["sunArchetype"] = userProfile.sunArchetype ?? ""
        profileData["moon"] = userProfile.moon ?? ""
        profileData["moonArchetype"] = userProfile.moonArchetype ?? ""
        profileData["ascendant"] = userProfile.ascendant ?? ""
        profileData["ascendantArchetype"] = userProfile.ascendantArchetype ?? ""
        profileData["strongestPlanet"] = userProfile.strongestPlanet ?? ""
        profileData["strongestPlanetArchetype"] = userProfile.strongestPlanetArchetype ?? ""
        profileData["strongestPlanetSignArchetype"] = userProfile.strongestPlanetSignArchetype ?? ""
        profileData["strongestAspects"] = userProfile.strongestAspects ?? ""
        profileData["bio"] = userProfile.bio ?? ""
        profileData["sentence"] = userProfile.sentence ?? ""
        profileData["role"] = userProfile.role ?? "user"
        
        // Include location data if available
        profileData["latitude"] = userProfile.latitude
        profileData["longitude"] = userProfile.longitude
        
        // Include birth date if available
        if let birthDate = userProfile.birthDate {
            profileData["birthDate"] = birthDate
        }
        
        return profileData
    }
}

// MARK: - Usage Example

// Add this to your AppDelegate or where you handle app startup/authentication
func applicationDidFinishLaunching(_ application: UIApplication) {
    // After Firebase is configured
    FirebaseApp.configure()
    
    // Check if user is logged in
    if Auth.auth().currentUser != nil {
        // User is logged in, check if migration is needed
        MigrationManager.shared.checkAndMigrateCurrentUserIfNeeded { success in
            if success {
                print("User data migration successful or already completed")
            } else {
                print("No migration performed or migration failed")
            }
        }
    }
}

// Also add this to your login success handler
func userDidLogin(user: User) {
    // After successful login
    MigrationManager.shared.checkAndMigrateCurrentUserIfNeeded { success in
        if success {
            print("User data migration successful or already completed")
        } else {
            print("No migration performed or migration failed")
        }
    }
}
