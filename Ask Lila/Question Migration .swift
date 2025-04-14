//
//  Question Migration .swift
//  Ask Lila
//
//  Created by Errick Williams on 3/31/25.
//

import Foundation
//
//  DataMigration.swift
//  AstroLogic
//
//  Created by Errick Williams on 3/16/25.
//

import Foundation
import UIKit
import CoreData
import FirebaseFirestore

class DataMigrationViewController: UIViewController {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var coreDataMessageCount = 0
    private var firestoreMessageCount = 0
    private var isExporting = false
    private var isMigratingUsers: Bool = false
    // UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Data Migration"
        view.backgroundColor = .systemBackground
        setupUI()
        
        // Register the cell for user migration
        tableView.register(UserMigrationCell.self, forCellReuseIdentifier: "userMigrationCell")
        
        fetchMessageCounts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchMessageCounts()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Set up table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(DataStatusCell.self, forCellReuseIdentifier: "statusCell")
        tableView.register(ExportCell.self, forCellReuseIdentifier: "exportCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Set up loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // Set up status label
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Set up progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        view.addSubview(progressView)
        
        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Operations
    private func fetchMessageCounts() {
        // Show loading
        loadingIndicator.startAnimating()
        statusLabel.text = "Fetching message counts..."
        
        // Get CoreData count
        fetchCoreDataMessageCount { [weak self] count in
            guard let self = self else { return }
            self.coreDataMessageCount = count
            
            // Get Firestore count
            self.fetchFirestoreMessageCount { count in
                self.firestoreMessageCount = count
                
                // Update UI
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.statusLabel.text = nil
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func fetchCoreDataMessageCount(completion: @escaping (Int) -> Void) {
        let context = CoreDataManager.shared.context
        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let count = try context.count(for: request)
                completion(count)
            } catch {
                print("Error counting CoreData messages: \(error)")
                completion(0)
            }
        }
    }
    
    private func fetchFirestoreMessageCount(completion: @escaping (Int) -> Void) {
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "defaultUser"
        
        db.collection("users").document(userId).collection("messages").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error counting Firestore messages: \(error)")
                completion(0)
                return
            }
            
            completion(snapshot?.documents.count ?? 0)
        }
    }
    
    // MARK: - Export Operation
    private func startExport() {
        guard !isExporting else { return }
        isExporting = true
        
        // Update UI
        loadingIndicator.startAnimating()
        statusLabel.text = "Starting export..."
        progressView.isHidden = false
        progressView.progress = 0
        tableView.reloadData()
        
        // Start export process with progress updates
        let exporter = ConversationDataExporter.shared
        
        // Prepare progress reporting
        exporter.onProgressUpdate = { [weak self] (progress, message) in
            DispatchQueue.main.async {
                self?.progressView.progress = Float(progress)
                self?.statusLabel.text = message
            }
        }
        
        // Run export
        exporter.exportAllConversationsToFirestore { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isExporting = false
                self.loadingIndicator.stopAnimating()
                self.progressView.isHidden = true
                
                if success {
                    let alert = UIAlertController(
                        title: "Export Complete",
                        message: "All conversations have been successfully exported to Firestore.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.fetchMessageCounts()
                    })
                    self.present(alert, animated: true)
                } else {
                    let alert = UIAlertController(
                        title: "Export Failed",
                        message: "There was an error exporting conversations: \(error?.localizedDescription ?? "Unknown error")",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Data Management
    private func clearCoreData() {
        let alert = UIAlertController(
            title: "Clear Local Storage",
            message: "This will delete all conversation history from your device. This action cannot be undone. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.performCoreDataClear()
        })
        
        present(alert, animated: true)
    }
    
    private func clearFirestore() {
        let alert = UIAlertController(
            title: "Clear Cloud Storage",
            message: "This will delete all conversation history from Firestore. This action cannot be undone. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.performFirestoreClear()
        })
        
        present(alert, animated: true)
    }
    
    private func performCoreDataClear() {
        // Show loading
        loadingIndicator.startAnimating()
        statusLabel.text = "Clearing local storage..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Clear CoreData conversations
            let context = CoreDataManager.shared.context
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ConversationMemory")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
                
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.loadingIndicator.stopAnimating()
                    self.statusLabel.text = nil
                    self.coreDataMessageCount = 0
                    self.tableView.reloadData()
                    
                    let alert = UIAlertController(
                        title: "Storage Cleared",
                        message: "Local conversation history has been successfully cleared.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.loadingIndicator.stopAnimating()
                    self.statusLabel.text = nil
                    
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to clear local storage: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func performFirestoreClear() {
        // Show loading
        loadingIndicator.startAnimating()
        statusLabel.text = "Clearing cloud storage..."
        
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "defaultUser"
        let messagesRef = db.collection("users").document(userId).collection("messages")
        
        // Get all messages
        messagesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.statusLabel.text = nil
                    
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to clear cloud storage: \(error?.localizedDescription ?? "Unknown error")",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
                return
            }
            
            // If no documents, just finish
            if documents.isEmpty {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.statusLabel.text = nil
                    self.firestoreMessageCount = 0
                    self.tableView.reloadData()
                    
                    let alert = UIAlertController(
                        title: "Storage Cleared",
                        message: "Cloud conversation history is already empty.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }
            
            // Use a batch to delete all documents
            let batch = self.db.batch()
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            // Commit the batch
            batch.commit { error in
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.statusLabel.text = nil
                    
                    if let error = error {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Failed to clear cloud storage: \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    } else {
                        self.firestoreMessageCount = 0
                        self.tableView.reloadData()
                        
                        let alert = UIAlertController(
                            title: "Storage Cleared",
                            message: "Cloud conversation history has been successfully cleared.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension DataMigrationViewController: UITableViewDelegate, UITableViewDataSource {
    // Update to return 4 sections instead of 3
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Add one section for user profile migration
    }

    // Update your numberOfRowsInSection method
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Statistics
        case 1: return 1 // Conversation Export
        case 2: return 1 // User Profile Migration (NEW)
        case 3: return 2 // Clear options (moved from section 2)
        default: return 0
        }
    }

    // Update your tableView:cellForRowAt: method
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // Statistics section (unchanged)
            if indexPath.row < 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "statusCell", for: indexPath) as! DataStatusCell
                
                if indexPath.row == 0 {
                    cell.configure(title: "Local Storage (CoreData)", count: coreDataMessageCount)
                } else {
                    cell.configure(title: "Cloud Storage (Firestore)", count: firestoreMessageCount)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = "Refresh Counts"
                cell.textLabel?.textColor = .systemBlue
                return cell
            }
            
        case 1:
            // Conversation export section (unchanged)
            let cell = tableView.dequeueReusableCell(withIdentifier: "exportCell", for: indexPath) as! ExportCell
            cell.configure(
                isExporting: isExporting,
                isEnabled: !isExporting && coreDataMessageCount > 0,
                onExport: { [weak self] in
                    self?.startExport()
                }
            )
            return cell
            
        case 2:
            // User migration section (NEW)
            let cell = tableView.dequeueReusableCell(withIdentifier: "userMigrationCell", for: indexPath) as! UserMigrationCell
            cell.configure(
                isMigrating: isMigratingUsers,
                isEnabled: !isMigratingUsers,
                onMigrate: { [weak self] in
                    self?.migrateUserProfiles()
                }
            )
            return cell
            
        case 3:
            // Data management section (moved from section 2)
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Clear Local Storage"
                cell.textLabel?.textColor = .systemRed
            } else {
                cell.textLabel?.text = "Clear Cloud Storage"
                cell.textLabel?.textColor = .systemRed
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }

    // Update section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Data Statistics"
        case 1: return "Conversation Migration"
        case 2: return "Profile Migration"
        case 3: return "Data Management"
        default: return nil
        }
    }

    // Update cell height method
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 || indexPath.section == 2 {
            return 120 // Both export cells are taller
        }
        return UITableView.automaticDimension
    }

    // Update didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 2 {
                fetchMessageCounts()
            }
            
        case 3: // Updated from case 2
            if indexPath.row == 0 {
                clearCoreData()
            } else {
                clearFirestore()
            }
            
        default:
            break
        }
    }

    // Add this method to implement user profile migration
    func migrateUserProfiles() {
        guard !isMigratingUsers else { return }
        isMigratingUsers = true
        tableView.reloadData()
        
        // Show loading
        loadingIndicator.startAnimating()
        statusLabel.text = "Starting user profile migration..."
        progressView.isHidden = false
        progressView.progress = 0
        // In migrateUserProfiles before starting migration
        print("Starting user profile migration")
        // Configure progress updates
        let migrationManager = UserDataMigrationManager.shared
        migrationManager.onProgressUpdate = { [weak self] (progress, message) in
            DispatchQueue.main.async {
                self?.progressView.progress = Float(progress)
                self?.statusLabel.text = message
            }
        }
        
        // Start migration
        migrationManager.migrateUserProfilesToFirestore { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isMigratingUsers = false
                self.loadingIndicator.stopAnimating()
                self.progressView.isHidden = true
                
                switch status {
                case .completed:
                    let alert = UIAlertController(
                        title: "Migration Complete",
                        message: "All user profiles have been successfully migrated to Firestore.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.fetchMessageCounts()
                    })
                    self.present(alert, animated: true)
                    // In the completion handler
                    print("Migration completed with status: \(status)")
                case .failed(let error):
                    let alert = UIAlertController(
                        title: "Migration Failed",
                        message: "There was an error migrating user profiles: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    
                case .inProgress:
                    // This shouldn't happen
                    break
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    
}

// MARK: - Custom Cells
class DataStatusCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(title: String, count: Int) {
        titleLabel.text = title
        countLabel.text = "\(count) messages"
    }
}

class ExportCell: UITableViewCell {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let exportButton = UIButton(type: .system)
    
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
        
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 10
        exportButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(exportButton)
        
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
            
            exportButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            exportButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            exportButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            exportButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(isExporting: Bool, isEnabled: Bool, onExport: @escaping () -> Void) {
        titleLabel.text = "Export All Conversations"
        descriptionLabel.text = "This will export all conversations from local storage (CoreData) to cloud storage (Firestore) for use in training and analytics."
        
        exportButton.setTitle(isExporting ? "Exporting..." : "Start Export", for: .normal)
        exportButton.isEnabled = isEnabled
        exportButton.alpha = isEnabled ? 1.0 : 0.5
        
        exportButton.removeTarget(nil, action: nil, for: .allEvents)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        
        self.onExport = onExport
    }
    
    private var onExport: (() -> Void)?
    
    @objc private func exportButtonTapped() {
        onExport?()
    }
}

class ConversationDataExporter {
    static let shared = ConversationDataExporter()
    
    private let db = Firestore.firestore()
    
    // Add progress reporting capability
    var onProgressUpdate: ((Double, String) -> Void)?
    
    func exportAllConversationsToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        // Step 1: Fetch all conversations from CoreData
        let conversations = fetchAllConversationsFromCoreData()
        
        // Step 2: Group conversations by date to organize them
        let conversationsByDate = groupConversationsByDate(conversations)
        
        // Step 3: Export each day's conversations to Firestore
        var successCount = 0
        var errorCount = 0
        let totalDays = conversationsByDate.count
        
        // Check if we have data to export
        if totalDays == 0 {
            print("No conversations found in CoreData to export.")
            onProgressUpdate?(1.0, "No conversations found to export.")
            completion(true, nil)
            return
        }
        
        // Report initial progress
        onProgressUpdate?(0.0, "Starting export of \(totalDays) conversation days...")
        
        // Array of dates to keep track of progress
        let sortedDates = conversationsByDate.keys.sorted()
        
        // Process each date one at a time to avoid overwhelming Firestore
        func processNextDate(index: Int) {
            // Check if we've finished
            if index >= sortedDates.count {
                let success = errorCount == 0
                print("Export complete. Successfully exported \(successCount)/\(totalDays) days.")
                onProgressUpdate?(1.0, "Export complete. Successfully exported \(successCount)/\(totalDays) days.")
                completion(success, nil)
                return
            }
            
            // Get the current date to process
            let date = sortedDates[index]
            let messages = conversationsByDate[date] ?? []
            
            // Update progress
            let progress = Double(index) / Double(totalDays)
            onProgressUpdate?(progress, "Exporting conversations for \(formatDate(date)) (\(index + 1)/\(totalDays))...")
            
            // Export this date's conversations
            exportConversationDay(date: date, messages: messages) { success, error in
                if success {
                    successCount += 1
                    print("Exported conversations for \(date) (\(successCount)/\(totalDays))")
                } else if let error = error {
                    errorCount += 1
                    print("Error exporting conversations for \(date): \(error.localizedDescription)")
                }
                
                // Process the next date with a small delay to avoid overwhelming Firestore
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    processNextDate(index: index + 1)
                }
            }
        }
        
        // Start processing with the first date
        processNextDate(index: 0)
    }
    
    // MARK: - Helper Methods
    
    private func fetchAllConversationsFromCoreData() -> [ConversationMemory] {
        let context = CoreDataManager.shared.context
        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        
        // Sort by timestamp to maintain chronological order
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            let conversations = try context.fetch(request)
            print("Found \(conversations.count) messages in CoreData")
            return conversations
        } catch {
            print("Error fetching from CoreData: \(error)")
            return []
        }
    }
    
    private func groupConversationsByDate(_ conversations: [ConversationMemory]) -> [Date: [ConversationMemory]] {
        var groupedConversations: [Date: [ConversationMemory]] = [:]

        for conversation in conversations {
            guard let timestamp = conversation.timestamp else { continue }
            
            // Use start of day as the key for grouping
            let startOfDay = timestamp.adjust(for: .startOfDay)!
            
            if groupedConversations[startOfDay] == nil {
                groupedConversations[startOfDay] = []
            }
            
            groupedConversations[startOfDay]?.append(conversation)
        }
        
        print("Grouped into \(groupedConversations.count) conversation days")
        return groupedConversations
    }
    
    private func exportConversationDay(date: Date, messages: [ConversationMemory], completion: @escaping (Bool, Error?) -> Void) {
        // Create a unique conversation ID for this day
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let conversationId = "coredata_export_\(dateFormatter.string(from: date))"
        
        // Reference to the conversation document
        let conversationRef = db.collection("conversations").document(conversationId)
        
        // Convert CoreData objects to Firestore format
        var firestoreMessages: [[String: Any]] = []
        
        for message in messages {
            guard let role = message.role, let content = message.content, let timestamp = message.timestamp else {
                continue
            }
            
            // Convert to the format used in Firestore
            let firestoreMessage: [String: Any] = [
                "id": message.id?.uuidString ?? UUID().uuidString,
                "text": content,
                "isFromUser": role == "user",
                "time": formatTimestamp(timestamp),
                "timestamp": timestamp,
                "role": role,
                // This might be nil, which is fine
            ]
            
            firestoreMessages.append(firestoreMessage)
        }
        
        // Batch operation to save all messages
        let batch = db.batch()
        
        // Save conversation metadata
        let metadata: [String: Any] = [
            "id": conversationId,
            "date": date,
            "messageCount": firestoreMessages.count,
            "exportDate": Date(),
            "source": "CoreData Export"
        ]
        
        batch.setData(metadata, forDocument: conversationRef)
        
        // Save each message in a subcollection
        for (index, message) in firestoreMessages.enumerated() {
            let messageId = message["id"] as? String ?? UUID().uuidString
            let messageRef = conversationRef.collection("messages").document(messageId)
            batch.setData(message, forDocument: messageRef)
            
            // Also add to user's messages collection for backward compatibility
            let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "defaultUser"
            let userMessageRef = db.collection("users").document(userId).collection("messages").document(messageId)
            batch.setData(message, forDocument: userMessageRef)
        }
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error saving to Firestore: \(error)")
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
