//
//  UserMigration.swift
//  Ask Lila
//
//  Created by Errick Williams on 4/14/25.
//

import Foundation
import CoreData
import FirebaseFirestore
import FirebaseAuth

class UserDataMigrationManager {
    static let shared = UserDataMigrationManager()
    private let db = Firestore.firestore()
    
    // MARK: - Migration Status
    enum MigrationStatus {
        case inProgress
        case completed
        case failed(Error)
    }
    
    // Add a callback for migration progress/completion
    typealias MigrationCallback = (MigrationStatus) -> Void
    var onProgressUpdate: ((Double, String) -> Void)?
    

    private func updateMigrationProgress(processedCount: inout Int, totalUsers: Int, successCount: Int, errorCount: Int) {
        processedCount += 1
        let progress = Double(processedCount) / Double(totalUsers)
        onProgressUpdate?(progress, "Processed \(processedCount)/\(totalUsers) users. Success: \(successCount), Errors: \(errorCount)")
    }
    
    private func completeMigration(successCount: Int, errors: [Error], completion: @escaping MigrationCallback) {
        if errors.isEmpty {
            onProgressUpdate?(1.0, "Migration completed successfully. Migrated \(successCount) users.")
            completion(.completed)
        } else {
            let combinedError = NSError(domain: "UserMigration", code: 500,
                                      userInfo: [NSLocalizedDescriptionKey: "Migration completed with \(errors.count) errors. Successfully migrated \(successCount) users."])
            onProgressUpdate?(1.0, "Migration completed with errors. Migrated \(successCount) users with \(errors.count) errors.")
            completion(.failed(combinedError))
        }
    }
    
    // MARK: - Data Conversion
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

    // MARK: - Core Data to Firestore Migration
    func migrateUserProfilesToFirestore(completion: @escaping MigrationCallback) {
        // First check if user is logged in
        guard let currentUser = Auth.auth().currentUser else {
            let error = NSError(domain: "UserMigration", code: 401, userInfo: [NSLocalizedDescriptionKey: "No logged-in user found. Authentication required for migration."])
            completion(.failed(error))
            return
        }
        
        // Start with progress update
        onProgressUpdate?(0.0, "Starting user profiles migration...")
        
        // Get Core Data context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            let error = NSError(domain: "UserMigration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not access AppDelegate"])
            completion(.failed(error))
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Fetch UserProfileEntity directly
        let fetchRequest: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if profiles.isEmpty {
                onProgressUpdate?(1.0, "No user profiles found to migrate")
                completion(.completed)
                return
            }
            
            onProgressUpdate?(0.2, "Found \(profiles.count) user profiles to migrate")
            
            // Process each user profile entity
            migrateUserProfileEntities(profiles, currentUserId: currentUser.uid) { status in
                // Forward the migration status to the completion handler
                completion(status)
            }
            
        } catch {
            onProgressUpdate?(0.0, "Failed to fetch user profile entities: \(error.localizedDescription)")
            completion(.failed(error))
        }
    }

    // Also add the full app migration method
    func migrateAllDataToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        // First migrate users
        migrateUserProfilesToFirestore { status in
            switch status {
            case .completed:
                // Then migrate conversations if needed
                if let exporter = ConversationDataExporter.shared as? ConversationDataExporter {
                    // Forward progress updates
                    exporter.onProgressUpdate = self.onProgressUpdate
                    
                    // Export conversations
                    exporter.exportAllConversationsToFirestore { success, error in
                        completion(success, error)
                    }
                } else {
                    // Just report success for user migration if conversation exporter not available
                    completion(true, nil)
                }
                
            case .failed(let error):
                // Report failure
                completion(false, error)
                
            case .inProgress:
                // This shouldn't happen since this is only called after completion
                completion(false, NSError(domain: "Migration", code: 500,
                                        userInfo: [NSLocalizedDescriptionKey: "Migration status reported as in progress during completion"]))
            }
        }
    }
    private func migrateUserProfileEntities(_ profiles: [UserProfileEntity], currentUserId: String, completion: @escaping MigrationCallback) {
        let totalProfiles = profiles.count
        var processedCount = 0
        var successCount = 0
        var errors: [Error] = []
        
        // For empty array, return immediately
        if totalProfiles == 0 {
            completion(.completed)
            return
        }
        
        // Process each user profile entity
        for profile in profiles {
            let userId = profile.uid ?? UUID().uuidString
            
            // Check if this is the current user
            let isCurrentUser = (userId == currentUserId)
            
            // Get user profile data
            let profileData = convertUserProfileToFirestoreData(profile)
            
            // Save to Firestore
            let docRef = db.collection("users").document(userId)
            
            // First check if document already exists
            docRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let error = error {
                    errors.append(error)
                    self.updateMigrationProgress(processedCount: &processedCount, totalProfiles: totalProfiles,
                                           successCount: successCount, errorCount: errors.count)
                    
                    // Check if all profiles have been processed
                    if processedCount == totalProfiles {
                        self.completeMigration(successCount: successCount, errors: errors, completion: completion)
                    }
                    return
                }
                
                let saveOperation: (Error?) -> Void = { error in
                    if let error = error {
                        errors.append(error)
                    } else {
                        successCount += 1
                    }
                    
                    self.updateMigrationProgress(processedCount: &processedCount, totalProfiles: totalProfiles,
                                           successCount: successCount, errorCount: errors.count)
                    
                    // Check if all profiles have been processed
                    if processedCount == totalProfiles {
                        self.completeMigration(successCount: successCount, errors: errors, completion: completion)
                    }
                }
                
                if let document = document, document.exists {
                    // Document exists, merge data
                    docRef.setData(profileData, merge: true) { error in
                        saveOperation(error)
                    }
                } else {
                    // Document doesn't exist, create new
                    docRef.setData(profileData) { error in
                        saveOperation(error)
                    }
                }
            }
        }
    }

    // Update the progress reporting method to use profiles instead of users
    private func updateMigrationProgress(processedCount: inout Int, totalProfiles: Int, successCount: Int, errorCount: Int) {
        processedCount += 1
        let progress = Double(processedCount) / Double(totalProfiles)
        onProgressUpdate?(progress, "Processed \(processedCount)/\(totalProfiles) profiles. Success: \(successCount), Errors: \(errorCount)")
    }
    
    // MARK: - Full App Migration
  
}


// MARK: - Date Extension for formatting
extension Date {
    func adjust(for adjustment: Calendar.Component) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        switch adjustment {
        case .day:
            components.hour = 0
            components.minute = 0
            components.second = 0
        case .hour:
            components.minute = 0
            components.second = 0
        default:
            break
        }
        
        return calendar.date(from: components)
    }
    
    var startOfDay: Date? {
        return adjust(for: .day)
    }
}
// Add this new cell class for the User Migration UI
class UserMigrationCell: UITableViewCell {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let migrateButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        migrateButton.backgroundColor = .systemBlue
        migrateButton.setTitleColor(.white, for: .normal)
        migrateButton.layer.cornerRadius = 10
        migrateButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        migrateButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(migrateButton)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            migrateButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            migrateButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            migrateButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            migrateButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(isMigrating: Bool, isEnabled: Bool, onMigrate: @escaping () -> Void) {
        titleLabel.text = "Migrate User Profiles"
        descriptionLabel.text = "This will migrate all user profiles from local storage (CoreData) to cloud storage (Firestore) for better sync and backup."
        
        migrateButton.setTitle(isMigrating ? "Migrating..." : "Start Migration", for: .normal)
        migrateButton.isEnabled = isEnabled
        migrateButton.alpha = isEnabled ? 1.0 : 0.5
        
        migrateButton.removeTarget(nil, action: nil, for: .allEvents)
        migrateButton.addTarget(self, action: #selector(migrateButtonTapped), for: .touchUpInside)
        
        self.onMigrate = onMigrate
    }
    
    private var onMigrate: (() -> Void)?
    
    @objc private func migrateButtonTapped() {
        onMigrate?()
    }
}

