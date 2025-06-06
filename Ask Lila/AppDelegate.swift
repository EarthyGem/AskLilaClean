//
//  AppDelegate.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/17/25.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseAuth
import AppTrackingTransparency
import StoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // ✅ Initialize Firebase
        FirebaseApp.configure()
        
        debugCoreDataStore()
        
        // Set up authentication state listener
        setupAuthStateListener()
        
        // Check if user is logged in and migrate if needed
        if Auth.auth().currentUser != nil {
            print("🔄 User is already logged in, checking for migration needs")
            MigrationManager.shared.checkAndMigrateCurrentUserIfNeeded { success in
                if success {
                    print("✅ User profile migration successful or already completed on app launch")
                } else {
                    print("⚠️ User profile migration not performed or failed on app launch")
                }
            }
        }
        
        // Override point for customization after application launch.
        return true
    }
    
    // Set up Firebase Auth state listener
    func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                // User just signed in
                print("👤 User signed in: \(user.uid)")
                
                // Update UserDefaults with Firebase UID
                UserDefaults.standard.set(user.uid, forKey: "currentUserId")
                
                // Check migration
                MigrationManager.shared.checkAndMigrateCurrentUserIfNeeded { success in
                    if success {
                        print("✅ User profile migration successful after sign-in")
                    } else {
                        print("⚠️ User profile migration not performed or failed after sign-in")
                    }
                }
            } else {
                // User signed out
                print("👋 User signed out")
                UserDefaults.standard.removeObject(forKey: "currentUserId")
            }
        }
    }

    // MARK: UISceneSession Lifecycle
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle custom URL schemes if needed
        return false
    }
   
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        print("Attempting to load Core Data model: Ask_Lila")
        let container = NSPersistentContainer(name: "Ask_Lila")
        
        // Create URL for the application support directory
        let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = storeDirectory.appendingPathComponent("Ask_Lila.sqlite")
        
        // Print the store URL for debugging
        print("📊 Core Data store URL: \(storeURL.path)")
        
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Failed to load persistent stores: \(error), \(error.userInfo)")
                
                // Only delete in extreme cases, and maybe add a user alert
                if error.domain == NSCocoaErrorDomain &&
                   (error.code == 134110 || error.code == 134100) {
                    // Consider backing up data before deleting
                    self.deleteAndRecreateStore()
                } else {
                    #if DEBUG
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                    #endif
                }
            } else {
                print("✅ Successfully loaded Core Data model")
                let entityNames = container.managedObjectModel.entities.map { $0.name ?? "Unknown" }
                print("✅ Available entities: \(entityNames)")
                
                // Debug: Check if any charts exist
                let context = container.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChartEntity")
                do {
                    let count = try context.count(for: fetchRequest)
                    print("📊 Found \(count) charts in database at launch")
                } catch {
                    print("❌ Error counting charts: \(error)")
                }
            }
        })
        return container
    }()
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func debugCoreDataStore() {
        let context = persistentContainer.viewContext
        
        // Print store URL
        if let storeURL = persistentContainer.persistentStoreDescriptions.first?.url {
            print("📊 Core Data store location: \(storeURL.path)")
            let fileExists = FileManager.default.fileExists(atPath: storeURL.path)
            print("📊 Core Data store file exists: \(fileExists)")
        }
        
        // Count each entity type
        let entityNames = persistentContainer.managedObjectModel.entities.map { $0.name ?? "Unknown" }
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            do {
                let count = try context.count(for: fetchRequest)
                print("📊 Entity \(entityName): \(count) records")
            } catch {
                print("❌ Error counting \(entityName): \(error)")
            }
        }
    }
    private func deleteAndRecreateStore() {
        print("Attempting to delete and recreate the Core Data store...")
        
        // Get the URL for the persistent store (use the same URL format as above)
        let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = storeDirectory.appendingPathComponent("Ask_Lila.sqlite")
        
        // Delete the file
        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("✅ Successfully deleted Core Data store at \(storeURL)")
            } else {
                print("⚠️ No Core Data store found at \(storeURL)")
            }
            
            // Reload the persistent container
            let container = NSPersistentContainer(name: "Ask_Lila")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
            
            container.loadPersistentStores { (description, error) in
                if let error = error {
                    print("❌ Still failed to load Core Data store: \(error)")
                } else {
                    print("✅ Successfully recreated Core Data store")
                }
            }
            
            // Replace the existing container
            self.persistentContainer = container
        } catch {
            print("❌ Failed to delete Core Data store: \(error)")
        }
    }
    // MARK: - Authentication Helper Methods
    
    func isUserLoggedIn() -> Bool {
        // First check Firebase Auth
        if Auth.auth().currentUser != nil {
            return true
        }
        // Fall back to UserDefaults check
        return UserDefaults.standard.string(forKey: "currentUserId") != nil
    }
    
    func loginUser(userId: String) {
        // Save user ID to UserDefaults
        UserDefaults.standard.set(userId, forKey: "currentUserId")
        
        // Check for migration needs when manually logging in
        MigrationManager.shared.checkAndMigrateCurrentUserIfNeeded { success in
            print("Manual login migration check: \(success ? "Completed" : "Failed/Skipped")")
        }
    }
    
    func logoutUser() {
        // Remove user ID from UserDefaults
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        
        // Also sign out from Firebase Auth
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

extension AppDelegate {
    // This will be called when app moves to the foreground
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Delay the request to avoid interfering with app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if #available(iOS 14.5, *) {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
            }
            
            // Check subscription status on app activation
            Task {
                await self.updateSubscriptionLevel()
            }
        }
    }
    
    
    @MainActor
    func updateSubscriptionLevel() async {
        var mostPrivilegedLevel: SubscriptionLevel?
        
        // Check for paid subscriptions first
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                print("⚠️ Non-verified transaction found")
                continue
            }
            
            print("✅ Verified transaction: \(transaction.productID)")
            
            switch transaction.productID {
            case "asklila.premiumAccess":
                if transaction.offerType == .introductory {
                    mostPrivilegedLevel = .introOffer
                } else {
                    mostPrivilegedLevel = .premium
                }
                
            case "asklila.fullAccess":
                // Only override if no more privileged subscription was found
                if mostPrivilegedLevel == nil {
                    mostPrivilegedLevel = .full
                }
                
            default:
                print("⚠️ Unknown product ID: \(transaction.productID)")
            }
        }
        
        if let level = mostPrivilegedLevel {
            AccessManager.shared.updateLevel(to: level)
        } else {
            // Get accurate trial status
            let trialManager = TrialUsageManager.shared
            let isInSneakPeek = trialManager.isInSneakPeekPeriod
            let hasRemainingUses = trialManager.hasAnyRemainingUses()
            
            // Set accurate subscription level
            if isInSneakPeek || hasRemainingUses {
                AccessManager.shared.updateLevel(to: .trial)
            } else {
                AccessManager.shared.updateLevel(to: .trialExpired)
            }
        }
        
        print("🔑 Final subscription level: \(AccessManager.shared.currentLevel)")
        
        // Update the banner if view controller is active
        if let window = UIApplication.shared.windows.first,
           let rootVC = window.rootViewController as? UINavigationController,
           let topVC = rootVC.topViewController as? MyAgentChatController {
            topVC.updateTrialBanner()
        }
        
    }
    
    //    //    @MainActor
    //       func updateSubscriptionLevel() async {
    //            // 🔧 Test One Type at a Time
    //
    //           let simulatedLevel: SubscriptionLevel = .trialExpired // ← change this to .trial, .full, .premium
    //
    //            AccessManager.shared.updateLevel(to: simulatedLevel)
    //            print("🧪 Forcing subscription level: \(simulatedLevel)")
    //
    //            // ✅ If your VC is active, update the banner UI immediately
    //            if let window = UIApplication.shared.windows.first,
    //               let rootVC = window.rootViewController as? UINavigationController,
    //               let topVC = rootVC.topViewController as? MyAgentChatController {
    //                topVC.updateTrialBanner()
    //            }
    //
    //            print("🔑 Final subscription level: \(AccessManager.shared.currentLevel)")
    //        }
    //    }
    
}
