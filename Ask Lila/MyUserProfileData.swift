//
//  MyUserProfileData.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/17/25.
//

import Foundation
import SwiftEphemeris
import CoreData
import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseAuth
public enum Sex: String {
    case male = "Male"
    case female = "Female"
}
class DataManager {
    static let shared = DataManager()
    var charts: [ChartEntity]?

    func fetchCharts(completion: @escaping ([ChartEntity]?) -> Void) {
        // Using Core Data stack
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            completion(nil)
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<ChartEntity>(entityName: "ChartEntity")

        do {
            let charts = try context.fetch(fetchRequest)
            self.charts = charts
            completion(charts)
        } catch {
            print("Failed to fetch charts: \(error.localizedDescription)")
            completion(nil)
        }
    }
}

protocol UserProfileDelegate: AnyObject {
    func didFinishEnteringUserProfile(with chartCake: ChartCake)
}

class MyUserProfileViewController: UIViewController, SuggestionsViewControllerDelegate, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    var motherChart: Chart? // Store mother chart data
    var fatherChart: Chart? // Store father chart data
    weak var delegate: UserProfileDelegate?

    var birthPlaceTimeZone: TimeZone? {
        didSet {
            datePicker.timeZone = birthPlaceTimeZone
            timePicker.timeZone = birthPlaceTimeZone
        }
    }
    let searchCompleter = MKLocalSearchCompleter()
    var suggestions: [MKLocalSearchCompletion] = []
    var searchRequest: MKLocalSearch.Request?

    var autocompleteSuggestions: [String] = []
    var id: UUID!
    var selectedDate: Date?
    var chart: Chart?
    
    var strongestPlanetSign: String?
    let locationManager = CLLocationManager()
    var harmonyDiscordScores: [String: (harmony: Double, discord: Double, difference: Double)]?
    var latitude: Double?
    var longitude: Double?
    let planetsInHouses = [Int: [String]]()
    var signScore: [String : Double] = [:]
    var planetScore: [String : Double] = [:]
    var houseScores: [Int : Double] = [:]
    var houseScore: [Int : Double] = [:]
    let houseCusps: [Cusp] = []
    var ascDeclination: Double?
    var mcDeclination: Double?
    var scores: [String : Double] = [:]
    var chartCake: ChartCake?
    var scores2: [CelestialObject : Double] = [:]
    var sex: Sex = .male // Default to male
    

    var toggleSwitch: UISwitch!
    let aboutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("About", for: .normal)
        button.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)
        button.addTarget(ViewController.self, action: #selector(showAboutViewController), for: .touchUpInside)
        return button
    }()

    lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "What would you like to be called?"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        return textField
    }()
    
    var selectedSubcategory: String?
    lazy var birthPlaceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Where were you born?"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.addTarget(self, action: #selector(birthPlaceTextFieldEditingDidBegin), for: .editingDidBegin)
        return textField
    }()

    lazy var sexSegmentedControl: UISegmentedControl = {
        let items = ["XY", "XX", ]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0 // Default to Male
        segmentedControl.addTarget(self, action: #selector(sexSegmentedControlChanged(_:)), for: .valueChanged)
        return segmentedControl
    }()

    var subcategory: String?
    lazy var dateTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "When were you born?"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        return textField
    }()

    lazy var birthTimeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "What time were you born?"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.textAlignment = .center // This centers the text horizontally
        textField.borderStyle = .roundedRect
        return textField
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        formatter.timeZone = birthPlaceTimeZone ?? TimeZone.current
        return formatter
    }()

    lazy var getPowerPlanetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enter", for: .normal)
        button.addTarget(self, action: #selector(saveMyChartButtonPressed), for: .touchUpInside)

        // Set background color to lavender
        button.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1)  // RGB values for lavender

        // Make button corners rounded
        button.layer.cornerRadius = 8.0

        // Set the title color to the color you provided
        button.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1), for: .normal)

        // Set font to bold and adjust the size accordingly
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17) // Adjust size to fit your needs

        return button
    }()

    lazy var scoresText: UILabel = {
        let scoresText = UILabel()
        scoresText.textColor = .white
        scoresText.numberOfLines = 0
        return scoresText
    }()

    lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.frame = CGRect(x: 0, y: 0, width: 250, height: 200)
        picker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        picker.timeZone = TimeZone.current // Use birthPlaceTimeZone

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = df.date(from: "1976-03-03 14:51:00") {
            picker.date = date
        }

        return picker
    }()

    lazy var timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.datePickerMode = .time
        picker.timeZone = TimeZone.current // Use birthPlaceTimeZone
        picker.frame = CGRect(x: 0, y: 0, width: 250, height: 200)
        picker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = df.date(from: "1976-03-03 14:51:00") {
            picker.date = date
        }

        return picker
    }()

    func searchPlace(_ place: String) {
       let searchRequest = MKLocalSearch.Request()
       searchRequest.naturalLanguageQuery = place

       let search = MKLocalSearch(request: searchRequest)
       search.start { (response, error) in
           if let error = error {
               print("Search error: \(error.localizedDescription)")
           } else if let response = response {
               // Handle the search results
               for item in response.mapItems {
                   print(item.name ?? "")
               }
           }
       }
    }

    // When the text in the text field changes, update the queryFragment property
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        searchCompleter.queryFragment = text!
       return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔍 DEBUG: MyUserProfileViewController viewDidLoad")
         debugPrintSavedData()
        searchCompleter.delegate = self
        birthPlaceTextField.delegate = self

        view.backgroundColor = UIColor(red: 236/255, green: 239/255, blue: 244/255, alpha: 1) // Light grey background for a clean look.

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 150))
        headerView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1)

        // Create the title label
        let titleLabel = UILabel(frame: CGRect(x: 15, y: headerView.bounds.height - 50, width: self.view.bounds.width - 80, height: 40))  // adjust width to leave space for button
        titleLabel.text = "Ask Lila"
        titleLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)
        if let customFont = UIFont(name: "Chalkduster", size: 30) {
            titleLabel.font = customFont
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 20)  // Backup in case the custom font fails
        }

        headerView.addSubview(titleLabel)

        // Add custom header to the main view BEFORE other subviews to ensure it's not overlapped
        self.view.addSubview(headerView)

        toggleSwitch = UISwitch()
        toggleSwitch.isOn = false // Set the initial state to "on"// Set the initial state as needed
        toggleSwitch.addTarget(self, action: #selector(toggleSwitchChanged(sender:)), for: .valueChanged)

        // Create a UIBarButtonItem with the UISwitch
        view.addSubview(birthPlaceTextField)
        view.addSubview(dateTextField)
        view.addSubview(birthPlaceTextField)
        view.addSubview(birthTimeTextField)
        birthTimeTextField.inputView = timePicker
        view.addSubview(aboutButton)
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aboutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            aboutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        view.addSubview(nameTextField)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(birthPlaceTextField)
        birthPlaceTextField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dateTextField)
        dateTextField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(birthTimeTextField)
        birthTimeTextField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(getPowerPlanetButton)
        getPowerPlanetButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(sexSegmentedControl)
        sexSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            nameTextField.widthAnchor.constraint(equalToConstant: 300),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),

            birthPlaceTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            birthPlaceTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            birthPlaceTextField.widthAnchor.constraint(equalToConstant: 300),
            birthPlaceTextField.heightAnchor.constraint(equalToConstant: 45),

            dateTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateTextField.topAnchor.constraint(equalTo: birthPlaceTextField.bottomAnchor, constant: 20),
            dateTextField.widthAnchor.constraint(equalToConstant: 300),
            dateTextField.heightAnchor.constraint(equalToConstant: 45),

            birthTimeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            birthTimeTextField.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 20),
            birthTimeTextField.widthAnchor.constraint(equalToConstant: 300),
            birthTimeTextField.heightAnchor.constraint(equalToConstant: 45),

            sexSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sexSegmentedControl.topAnchor.constraint(equalTo: birthTimeTextField.bottomAnchor, constant: 20),
            sexSegmentedControl.widthAnchor.constraint(equalToConstant: 300),
            sexSegmentedControl.heightAnchor.constraint(equalToConstant: 45),

            getPowerPlanetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getPowerPlanetButton.topAnchor.constraint(equalTo: sexSegmentedControl.bottomAnchor, constant: 30),
            getPowerPlanetButton.widthAnchor.constraint(equalToConstant: 300),
            getPowerPlanetButton.heightAnchor.constraint(equalToConstant: 45)
        ])

        dateTextField.inputView = datePicker
        view.addSubview(nameTextField)

        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(datePickerDonePressed))
        toolBar.setItems([doneBtn], animated: true)
        dateTextField.inputAccessoryView = toolBar

        let timePickerToolBar = UIToolbar()
        timePickerToolBar.sizeToFit()
        let timePickerDoneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(timePickerDonePressed))
        timePickerToolBar.setItems([timePickerDoneBtn], animated: true)
        birthTimeTextField.inputAccessoryView = timePickerToolBar

        view.addSubview(birthPlaceTextField)
        birthPlaceTextField.delegate = self // Set the delegate for the birthPlaceTextField
        birthPlaceTextField.addTarget(self, action: #selector(birthPlaceTextFieldEditingDidBegin), for: .editingDidBegin) // Add this line

        view.addSubview(getPowerPlanetButton)

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        setupSexSegmentedControl() // Call this to set up the segmented control
    }

    // PickerView delegate and data source methods for subcategories
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    @objc func sexSegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            sex = .male
        case 1:
            sex = .female
        default:
            break
        }
    }

    func setupSexSegmentedControl() {
        // Add target-action for the segmented control
        sexSegmentedControl.addTarget(self, action: #selector(sexSegmentedControlChanged(_:)), for: .valueChanged)
        // Set default selection
        sexSegmentedControl.selectedSegmentIndex = 0 // Default to male
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        DataManager.shared.fetchCharts { [weak self] charts in
            guard self != nil else { return }
            // Store the charts data or pass it to RelationshipsViewController
        }
    }

    @objc func toggleSwitchChanged(sender: UISwitch) {
        // Handle switch state changes here
        // You can access sender.isOn to determine the new state (true for on, false for off)

        // Apply changes to all the charts based on the new switch state
        if sender.isOn {
            // Apply changes when the switch is on
        } else {
            // Apply changes when the switch is off
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar again
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func updateSearchBarTextColor(in view: UIView, to color: UIColor) {
        if let textField = view as? UITextField {
            textField.textColor = color
            return
        } else {
            for subview in view.subviews {
                updateSearchBarTextColor(in: subview, to: color)
            }
        }
    }

    @objc func birthPlaceTextFieldEditingDidBegin() {
        let suggestionsVC = SuggestionsViewController()
        suggestionsVC.delegate = self
        present(suggestionsVC, animated: true, completion: nil)
    }

    func suggestionSelected(_ suggestion: MKLocalSearchCompletion) {
        // Combine the title and subtitle if the subtitle is not empty
        if !suggestion.subtitle.isEmpty {
            birthPlaceTextField.text = "\(suggestion.title), \(suggestion.subtitle)"
        } else {
            // If there is no subtitle, just use the title
            birthPlaceTextField.text = suggestion.title
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let suggestions = completer.results

        if let suggestionsVC = presentedViewController as? SuggestionsViewController {
            suggestionsVC.autocompleteSuggestions = suggestions
            suggestionsVC.tableView.reloadData()
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle the error
        print("Search error: \(error.localizedDescription)")
    }

    func didSelectPlace(_ place: String) {
        // Handle the selected place, e.g., update the birthplace text field with 'place'
        birthPlaceTextField.text = place
    }

    func formattedPlanetScores(_ scores: [CelestialObject: Double]) -> [String] {
        let totalScore = scores.values.reduce(0, +)
        return scores
            .sorted { $0.value > $1.value }
            .map { (key, value) in
                let percentage = (value / totalScore) * 100
                return "\(key.keyName) \(String(format: "%.1f%%", percentage))"
            }
    }

    func formattedSignScores(_ scores: [Zodiac: Double]) -> [String] {
        let totalScore = scores.values.reduce(0, +)
        return scores
            .sorted { $0.value > $1.value }
            .map { (key, value) in
                let percentage = (value / totalScore) * 100
                return "\(key.keyName) \(String(format: "%.1f%%", percentage))"
            }
    }

    func formattedHouseScores(_ scores: [Int: Double]) -> [String] {
        let totalScore = scores.values.reduce(0, +)
        return scores
            .sorted { $0.value > $1.value }
            .map { (key, value) in
                let percentage = (value / totalScore) * 100
                return "House \(key) \(String(format: "%.1f%%", percentage))"
            }
    }
    
    // This method calculates Local Mean Time based on the longitude
    func calculateLMT(longitude: Double) -> TimeZone {
        // Longitude is in degrees, converting to hours (1 hour per 15 degrees)
        let lmtOffsetInSeconds = TimeInterval(longitude * 240) // 3600 sec/hour / 15 degrees/hour

        // Create a custom timezone based on the offset
        let secondsFromGMT = Int(lmtOffsetInSeconds)
        guard let lmtTimeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
            // Default to GMT if the custom calculation fails
            return TimeZone(abbreviation: "GMT")!
        }

        return lmtTimeZone
    }

    func resetViewController() {
        // Clear input fields
        birthPlaceTextField.text = ""
        nameTextField.text = ""
        datePicker.setDate(Date(), animated: true)
        timePicker.setDate(Date(), animated: true)

        // Reset the time zone of the UIDatePicker based on the input in the birthPlaceTextField
        if let birthPlace = birthPlaceTextField.text,
           let timeZone = TimeZone(identifier: birthPlace) {
            timePicker.timeZone = timeZone
        }
    }

    func formattedHarmonyDiscordNetScores(_ scores: [CelestialObject: (harmony: Double, discord: Double, netHarmony: Double)]) -> [String] {
        return scores
            .sorted { $0.value.netHarmony > $1.value.netHarmony }
            .map { (key, value) in
                let harmony = String(format: "%.1f", value.harmony)
                let discord = String(format: "%.1f", value.discord)
                let net = String(format: "%.1f", value.netHarmony)
                return "\(key.keyName): Harmony: \(harmony), Discord: \(discord), Net Harmony: \(net)"
            }
    }

    func getStrongestPlanet(from scores: [CelestialObject: Double]) -> CelestialObject {
        let sorted = scores.sorted { $0.value > $1.value }
        let strongestPlanet = sorted.first!.key
        return strongestPlanet
    }

    func getPlanetsSortedByStrength(from scores: [CelestialObject: Double]) -> [CelestialObject] {
        let sortedPlanets = scores.sorted { $0.value > $1.value }.map { $0.key }
        return sortedPlanets
    }

    func createDate(day: Int, month: Int, year: Int) -> Date? {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year
        return calendar.date(from: dateComponents)
    }

    func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func getMostHarmoniousPlanet(from scores: [CelestialObject: (harmony: Double, discord: Double, netHarmony: Double)]) -> CelestialObject {
        let sorted = scores.sorted { $0.value.netHarmony > $1.value.netHarmony }
        let mostHarmoniousPlanet = sorted.first!.key
        return mostHarmoniousPlanet
    }

    func getMostDiscordantPlanet(from scores: [CelestialObject: (harmony: Double, discord: Double, netHarmony: Double)]) -> CelestialObject {
        let sorted = scores.sorted { $0.value.netHarmony < $1.value.netHarmony }
        let mostDiscordantPlanet = sorted.first!.key
        return mostDiscordantPlanet
    }
}

extension MyUserProfileViewController {
    
    func saveUserProfileToCoreData(profile: UserProfileEntity) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ Error: Could not access AppDelegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Check if user exists
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            let userEntity: UserEntity
            
            if let existingUser = results.first {
                userEntity = existingUser
            } else {
                userEntity = UserEntity(context: context)
                userEntity.userId = userId
                UserDefaults.standard.set(userId, forKey: "currentUserId")
            }
            
            // Update user fields
            userEntity.displayName = profile.displayName
            userEntity.email = profile.email
            userEntity.lastLoginDate = Date()
            
            try context.save()
            print("✅ User profile saved to CoreData successfully")
            
        } catch {
            print("❌ Error saving user profile to CoreData: \(error.localizedDescription)")
        }
    }

    func saveUserProfile(displayName: String,
                         sun: String,
                         moon: String,
                         ascendant: String,
                         strongestPlanet: String,
                         strongestAspects: String,
                         sentenceText: String,
                         bio: String,
                         chartCake: ChartCake) {

        print("🔹 DEBUG: saveUserProfile called with displayName: \(displayName)")

        let profile = UserProfileEntity()
        profile.displayName = displayName
        profile.email = UserDefaults.standard.string(forKey: "userEmail")
        profile.uid = UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
        profile.sun = sun
        profile.moon = moon
        profile.ascendant = ascendant
        profile.strongestPlanet = strongestPlanet
        profile.strongestAspects = strongestAspects
        profile.bio = bio

        print("🔹 DEBUG: About to call saveUserProfileToCoreData")
        saveUserProfileToCoreData(profile: profile)

        print("🔹 DEBUG: About to call saveUserProfileToFirestore")
        saveUserProfileToFirestore(profile: profile) { success in
            if success {
                print("✅ Firestore save succeeded")
            } else {
                print("❌ Firestore save failed")
            }
        }

        // ✅ Triggering delegate call
        print("🔹 DEBUG: About to trigger delegate")
        if let delegate = self.delegate {
            print("🎯 DEBUG: Calling delegate with chartCake: \(chartCake.name ?? "Unnamed")")
            delegate.didFinishEnteringUserProfile(with: chartCake)
        } else {
            print("🚫 DEBUG: Delegate is nil — cannot navigate to main screen")
        }
    }



  
    func clearSearchBarText(in view: UIView) {
        if let searchBar = view as? UISearchBar {
            searchBar.text = ""
            return
        } else {
            for subview in view.subviews {
                clearSearchBarText(in: subview)
            }
        }
    }

    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        dateFormatter.timeZone = birthPlaceTimeZone // Use the birthPlaceTimeZone here
        let dateString = dateFormatter.string(from: selectedDate)
        dateTextField.text = dateString
    }

    @objc func datePickerDonePressed() {
        // Set the time zone for the date picker
        dateTextField.resignFirstResponder()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }

    @objc func timePickerDonePressed() {
        birthTimeTextField.resignFirstResponder()
    }
    
    @objc func timePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = sender.timeZone
        dateFormatter.dateFormat = "h:mm a" // Adjust this to your desired format
        birthTimeTextField.text = dateFormatter.string(from: sender.date)
    }

    func resetDateAndTimePickers() {
        let now = Date()
        datePicker.date = now
        timePicker.date = now
        // Ensure to reset the time zone or any other configurations you have set before
        datePicker.timeZone = TimeZone.autoupdatingCurrent
        timePicker.timeZone = TimeZone.autoupdatingCurrent
        print("Date and Time pickers have been reset to current date and time.")
    }

    func formattedHouseHarmonyDiscordScores(_ scores: [Int: Double]) -> [String] {
        return scores.sorted { $0.value > $1.value }
                     .map { houseNumber, score in
                         "House \(houseNumber): Net Harmony/Discord Score: \(String(format: "%.2f", score))"
                     }
    }

    func formattedSignHarmonyDiscordScores(_ scores: [Zodiac: Double]) -> [String] {
        return scores.sorted { $0.value > $1.value }
                     .map { sign, score in
                         "\(sign.keyName): Net Harmony/Discord Score: \(String(format: "%.2f", score))"
                     }
    }


    @objc func showAboutViewController() {
        let aboutVC = AboutViewController()
        navigationController?.pushViewController(aboutVC, animated: true)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == birthPlaceTextField {
            let suggestionsVC = SuggestionsViewController()
            suggestionsVC.delegate = self // Set the delegate
            present(suggestionsVC, animated: true, completion: nil)
            return false
        }
        return true
    }


    // In MyUserProfileViewController.swift
    // In MyUserProfileViewController.swift
    func saveChartCakeToUserDefaults() {
        guard let chartCake = self.chartCake else {
            print("❌ ERROR: Cannot save to UserDefaults: chartCake is nil")
            return
        }
        
        print("🔍 DEBUG: Saving chartCake to UserDefaults via UserDefaultsManager")
        UserDefaultsManager.shared.saveChart(chartCake)
        print("✅ DEBUG: Chart saved with UserDefaultsManager")
    }
    
    
    func loadChartFromUserDefaultsIfNeeded() {
        // Only attempt to load if chartCake is nil
        if chartCake == nil {
            print("🔍 DEBUG: Loading chart from UserDefaults via UserDefaultsManager")
            chartCake = UserDefaultsManager.shared.loadChart()
            
            if chartCake != nil {
                print("✅ DEBUG: Successfully loaded chart with UserDefaultsManager")
            } else {
                print("⚠️ DEBUG: No chart found in UserDefaults")
            }
        }
    }
    
    func saveChartToCoreData(chart: ChartCake, completion: @escaping (String?) -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error: Could not access AppDelegate")
            completion(nil)
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a new ChartEntity
        let chartEntity = ChartEntity(context: context)
        
        // Set the properties
        chartEntity.name = chart.name
        chartEntity.birthDate = chart.natal.birthDate
        chartEntity.latitude = chart.natal.latitude
        chartEntity.longitude = chart.natal.longitude
        chartEntity.birthPlace = "" // Fill in if available
        chartEntity.strongestPlanet = chart.strongestPlanetSN.keyName
        chartEntity.mostHarmoniousPlanet = chart.mostHarmoniousPlanetSN.keyName
        chartEntity.mostDiscordantPlanet = chart.mostDiscordantPlanetSN.keyName
        chartEntity.timeZoneIdentifier = birthPlaceTimeZone?.identifier ?? TimeZone.current.identifier
        chartEntity.category = "Other" // Use default or provide actual category
        chartEntity.sentenceText = "" // Generate if needed
        
        // Generate and assign a UUID as chartID
        let chartID = UUID().uuidString
        chartEntity.chartID = chartID
        
        // Associate with user if logged in
        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
            // Set the ID property if still needed (for backward compatibility)
            chartEntity.id = userId
            
            // Fetch the user entity to establish relationship
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let userEntity = results.first {
                    // Set the relationship bidirectionally
                    chartEntity.user = userEntity  // Set the to-one relationship from chart to user
                    
                    // Add this chart to the user's charts collection using proper Core Data methods
                    userEntity.mutableSetValue(forKey: "charts").add(chartEntity)
                }
            } catch {
                print("Error fetching user entity: \(error.localizedDescription)")
            }
        }
        
        // Save the context
        do {
            try context.save()
            print("✅ Chart saved to CoreData successfully")
            completion(chartID)
        } catch {
            print("❌ Error saving chart to CoreData: \(error.localizedDescription)")
            completion(nil)
        }
    }
    func saveChart(name: String, birthDate: Date, latitude: Double, longitude: Double, birthPlace: String, strongestPlanet: String, sex: Sex, mostHarmoniousPlanet: String, mostDiscordantPlanet: String, sentenceText: String, strongestPlanetSign: String, strongestPlanetArchetype: String, timeZoneIdentifier: String, momsName: Date? = nil, dadsName: Date? = nil, momsBD: Date? = nil, dadsBD: Date? = nil, momsLat: Double? = nil, momsLong: Double? = nil, dadsLat: Double? = nil, dadsLong: Double? = nil, chartID: String? = nil) {
        print("⭐️ DEBUG: saveChart function called with name: \(name)")
        
        // Get Core Data context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ ERROR: Unable to get AppDelegate")
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        print("✅ DEBUG: Got managed object context")
        
        // Create and configure chart entity
        let chartEntity = ChartEntity(context: context)
        configureChartEntity(chartEntity, name: name, birthDate: birthDate, latitude: latitude, longitude: longitude,
                             birthPlace: birthPlace, strongestPlanet: strongestPlanet, sex: sex.rawValue,
                             mostHarmoniousPlanet: mostHarmoniousPlanet, mostDiscordantPlanet: mostDiscordantPlanet,
                             sentenceText: sentenceText, strongestPlanetSign: strongestPlanetSign,
                             strongestPlanetArchetype: strongestPlanetArchetype, timeZoneIdentifier: timeZoneIdentifier,
                             chartID: chartID)
        print("✅ DEBUG: Chart entity configured")
        
        // Save context
        do {
            try context.save()
            print("✅ DEBUG: Chart saved to Core Data successfully")
            
            // Update chartCake and navigate to next screen
            updateChartCakeAndNavigate(chartEntity: chartEntity)
        } catch {
            handleSaveError(error)
        }
    }

    // Helper method to configure the chart entity
    private func configureChartEntity(_ chartEntity: ChartEntity, name: String, birthDate: Date, latitude: Double,
                                     longitude: Double, birthPlace: String, strongestPlanet: String, sex: String,
                                     mostHarmoniousPlanet: String, mostDiscordantPlanet: String, sentenceText: String,
                                     strongestPlanetSign: String, strongestPlanetArchetype: String,
                                     timeZoneIdentifier: String, chartID: String?) {
        // Basic chart properties
        chartEntity.name = name
        chartEntity.birthDate = birthDate
        chartEntity.latitude = latitude
        chartEntity.longitude = longitude
        chartEntity.birthPlace = birthPlace
        chartEntity.timeZoneIdentifier = timeZoneIdentifier
        
        // Chart analysis properties
        chartEntity.strongestPlanet = strongestPlanet
        chartEntity.sex = sex
        chartEntity.mostHarmoniousPlanet = mostHarmoniousPlanet
        chartEntity.mostDiscordantPlanet = mostDiscordantPlanet
        chartEntity.sentenceText = sentenceText
        chartEntity.strongestPlanetSign = strongestPlanetSign
        chartEntity.strongestPlanetArchetype = strongestPlanetArchetype
        
        // Set unique identifier
        chartEntity.chartID = chartID ?? UUID().uuidString
        
        // Associate with current user
        let userId = UserDefaults.standard.string(forKey: "currentUserId")
        print("🔍 DEBUG: Current UserID from UserDefaults: \(userId ?? "nil")")
        chartEntity.id = userId
        
        // Set up relationship with UserEntity if userId exists
        if let userId = userId {
            establishUserRelationship(for: chartEntity, userId: userId)
        }
    }

    // Helper method to establish relationship with user
    private func establishUserRelationship(for chartEntity: ChartEntity, userId: String) {
        guard let context = chartEntity.managedObjectContext else { return }
        
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let userEntity = results.first {
                // Set bidirectional relationship
                chartEntity.user = userEntity
                userEntity.mutableSetValue(forKey: "charts").add(chartEntity)
                print("✅ DEBUG: Established relationship with user")
            }
        } catch {
            print("❌ ERROR: Failed to establish user relationship: \(error.localizedDescription)")
        }
    }

    // Helper method to update chartCake and navigate
    // In MyUserProfileViewController.swift
    private func updateChartCakeAndNavigate(chartEntity: ChartEntity) {
        // Update chartCake with ID
        self.chartCake?.firestoreID = chartEntity.chartID
        print("✅ DEBUG: Updated chartCake.firestoreID: \(chartEntity.chartID ?? "nil")")
        
        guard let chartCake = self.chartCake else {
            print("❌ ERROR: ChartCake is nil after saving")
            return
        }
        
        // Use the UserDefaultsManager to save the chart
        print("🔍 DEBUG: Saving chart to UserDefaults before navigation")
        UserDefaultsManager.shared.saveChart(chartCake)
        print("✅ DEBUG: Chart successfully saved to UserDefaults")
        
        // Call delegate directly
        if let delegate = self.delegate {
            print("✅ DEBUG: Calling delegate.didFinishEnteringUserProfile")
            DispatchQueue.main.async {
                delegate.didFinishEnteringUserProfile(with: chartCake)
            }
            return
        }
        
        // Fallback to direct navigation if delegate is nil
        print("⚠️ WARNING: Delegate is nil, using fallback navigation")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let chatVC = MyAgentChatController()
            chatVC.chartCake = self.chartCake
            self.navigationController?.pushViewController(chatVC, animated: true)
            print("✅ DEBUG: Used fallback navigation to MyAgentChatController")
        }
    }
    
    // Add this method to help with debugging
    func debugPrintSavedData() {
        if let chartData = UserDefaults.standard.dictionary(forKey: "savedChartCake") {
            print("✅ DEBUG: Found chart data in UserDefaults with keys: \(chartData.keys)")
            if let name = chartData["name"] as? String {
                print("✅ DEBUG: Chart belongs to: \(name)")
            }
            if let birthDateInterval = chartData["birthDate"] as? TimeInterval {
                let birthDate = Date(timeIntervalSince1970: birthDateInterval)
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                print("✅ DEBUG: Birth date: \(formatter.string(from: birthDate))")
            }
        } else {
            print("⚠️ DEBUG: No chart data found in UserDefaults")
        }
    }
    // Helper method to handle save errors
    private func handleSaveError(_ error: Error) {
        print("❌ ERROR: Failed to save ChartEntity to Core Data: \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            print("❌ ERROR Details: Domain: \(nsError.domain), Code: \(nsError.code)")
            print("❌ ERROR User Info: \(nsError.userInfo)")
            
            // Show an alert to the user
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(
                    title: "Save Error",
                    message: "Could not save chart: \(nsError.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    func adjustForTimeZoneException(date: Date, location: String, latitude: Double, longitude: Double, geocodedTimeZoneIdentifier: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Define the threshold date for using LMT (before standardized time zones were adopted)
        let thresholdDate = Calendar.current.date(from: DateComponents(year: 1883, month: 11, day: 18))!

        // If the date is before the threshold, calculate Local Mean Time (LMT)
        if date < thresholdDate {
            print("Using LMT before \(dateFormatter.string(from: thresholdDate)) for location \(location)")
            return "LMT" // We return a flag to indicate LMT
        }

        // Otherwise, check if there are any time zone exceptions
        let exceptions = loadTimeZoneExceptions()
        print("Adjusting for time zone exceptions on \(dateFormatter.string(from: date)) at location \(location)")

        for exception in exceptions {
            print("Checking exception for \(exception.location) from \(dateFormatter.string(from: exception.startDate)) to \(dateFormatter.string(from: exception.endDate))")
            if exception.location == location,
               date >= exception.startDate,
               date <= exception.endDate {
                print("Time zone exception found for \(location): \(exception.timeZoneIdentifier) overrides geocoded time zone \(geocodedTimeZoneIdentifier)")
                return exception.timeZoneIdentifier
            }
        }

        print("No time zone exception applicable. Using geocoded time zone: \(geocodedTimeZoneIdentifier)")
        return geocodedTimeZoneIdentifier // Use geocoded time zone if no exception found
    }

    func loadTimeZoneExceptions() -> [TimeZoneException] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let exceptions: [TimeZoneException] = [
            TimeZoneException(location: "Atlanta, GA, United States", startDate: dateFormatter.date(from: "1918-01-01")!, endDate: dateFormatter.date(from: "1931-12-03")!, timeZoneIdentifier: "America/Chicago", offset: "-06:00"),
            TimeZoneException(location: "Hope, AR, United States", startDate: dateFormatter.date(from: "1946-01-01")!, endDate: dateFormatter.date(from: "1946-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-06:00"),
            TimeZoneException(location: "Louisville, KY, United States", startDate: dateFormatter.date(from: "1942-01-01")!, endDate: dateFormatter.date(from: "1945-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-04:00"),
            TimeZoneException(location: "Flatwoods, KY, United States", startDate: dateFormatter.date(from: "1961-01-01")!, endDate: dateFormatter.date(from: "1961-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-04:00")
        ]
        for exception in exceptions {
            print("Loaded time zone exception for \(exception.location) from \(dateFormatter.string(from: exception.startDate)) to \(dateFormatter.string(from: exception.endDate)) with offset \(exception.offset)")
        }
        return exceptions
    }
    
    @objc func saveMyChartButtonPressed() {
        print("⭐️ DEBUG: saveMyChartButtonPressed started")
        print("⭐️ DEBUG: saveMyChartButtonPressed started")
        print("DEBUG: Sex before saving -> \(sex.rawValue)")
        print("🔍 DEBUG: UserProfileDelegate is set: \(delegate != nil)")
        
        let selectedSexIndex = sexSegmentedControl.selectedSegmentIndex
        switch selectedSexIndex {
        case 0:
            sex = .male
        case 1:
            sex = .female
        default:
            sex = .male // Default fallback
        }

        print("DEBUG: Updated Sex -> \(sex.rawValue)")

        // Log analytics event
        logEvent("chart_added")
        // Disable button immediately to prevent spamming
        getPowerPlanetButton.isEnabled = false

        // Guard against missing input
        guard let location = birthPlaceTextField.text, !location.isEmpty else {
            showErrorAlert(title: "Missing Information", message: "Please enter your birth place")
            getPowerPlanetButton.isEnabled = true
            return
        }

        guard let _ = dateTextField.text, !dateTextField.text!.isEmpty else {
            showErrorAlert(title: "Missing Information", message: "Please enter your birth date")
            getPowerPlanetButton.isEnabled = true
            return
        }

        guard let _ = birthTimeTextField.text, !birthTimeTextField.text!.isEmpty else {
            showErrorAlert(title: "Missing Information", message: "Please enter your birth time")
            getPowerPlanetButton.isEnabled = true
            return
        }

     
        sex = selectedSexIndex == 1 ? .female : .male
        print("DEBUG: Sex set to \(sex.rawValue)")

        print("🔍 DEBUG: Starting geocoding for location: \(location)")

        // Begin geocoding
        geocoding(location: location) { [weak self] latitude, longitude in
            guard let self = self else { return }

            print("✅ DEBUG: Geocoding successful - Lat: \(latitude), Long: \(longitude)")
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            getTimeZone(location: coordinate) { [weak self] timeZone in
                guard let self = self else { return }

                let fallbackTimeZone = TimeZone.current
                let timeZoneToUse = timeZone ?? fallbackTimeZone
                print("📍 Time zone resolved: \(timeZoneToUse.identifier)")

                // Handle LMT exception override
                let adjustedTimeZoneIdentifier = self.adjustForTimeZoneException(
                    date: self.datePicker.date,
                    location: location,
                    latitude: latitude,
                    longitude: longitude,
                    geocodedTimeZoneIdentifier: timeZoneToUse.identifier
                )

                let finalTimeZone: TimeZone = (adjustedTimeZoneIdentifier == "LMT")
                    ? self.calculateLMT(longitude: longitude)
                    : (TimeZone(identifier: adjustedTimeZoneIdentifier) ?? fallbackTimeZone)

                self.birthPlaceTimeZone = finalTimeZone
                self.datePicker.timeZone = finalTimeZone
                self.timePicker.timeZone = finalTimeZone

                // Combine birth date + time safely
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: self.datePicker.date)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: self.timePicker.date)

                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                dateComponents.timeZone = finalTimeZone

                guard let combinedDate = calendar.date(from: dateComponents) else {
                    self.showErrorAlert(title: "Date Error", message: "Could not combine date and time")
                    self.getPowerPlanetButton.isEnabled = true
                    return
                }

                print("📅 Combined date & time: \(combinedDate) in \(finalTimeZone.identifier)")

                // Create chartCake
                let fallbackTransitDate = self.selectedDate ?? Date()
                let chartCake = ChartCake(
                    birthDate: combinedDate,
                    latitude: latitude,
                    longitude: longitude,
                    transitDate: fallbackTransitDate,
                    name: self.nameTextField.text
                )
                self.chartCake = chartCake
                print("🎂 ChartCake created: \(chartCake.name ?? "Unnamed")")

                
                
                
                
                // Save to UserDefaults
                UserDefaultsManager.shared.saveChart(chartCake)
                print("💾 ChartCake saved to UserDefaults")
                let profile = UserProfileEntity()
        

                // Save to CoreData
                self.saveChart(
                    name: self.nameTextField.text ?? "Unnamed",
                    birthDate: combinedDate,
                    latitude: latitude,
                    longitude: longitude,
                    birthPlace: location,
                    strongestPlanet: "", // Populate if calculated
                    sex: self.sex,
                    mostHarmoniousPlanet: "",
                    mostDiscordantPlanet: "",
                    sentenceText: "",
                    strongestPlanetSign: self.strongestPlanetSign ?? "",
                    strongestPlanetArchetype: "Archetype",
                    timeZoneIdentifier: finalTimeZone.identifier
                )
            
                print("📦 Chart saved to CoreData")

                // Handle fallback nav after timeout if no delegate fires
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard let chartCake = self.chartCake, self.isViewLoaded, self.view.window != nil else { return }
                    let chatVC = MyAgentChatController()
                    chatVC.chartCake = chartCake
                    self.navigationController?.pushViewController(chatVC, animated: true)
                    print("🧭 Fallback navigation triggered")
                }

                self.getPowerPlanetButton.isEnabled = true
            }
        } failure: { [weak self] errorMsg in
            self?.getPowerPlanetButton.isEnabled = true
            self?.showErrorAlert(title: "Location Error", message: errorMsg)
        }
    }

    
    func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    // Helper method to save AstroChartData to CoreData
    func saveAstroChartDataToCoreData(data: [String: Any]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error: Could not access AppDelegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a new AstroChartDataEntity
        let entity = NSEntityDescription.entity(forEntityName: "AstroChartDataEntity", in: context)!
        let astroChartDataEntity = NSManagedObject(entity: entity, insertInto: context)
        
        // Set properties from dictionary
        for (key, value) in data {
            // Handle special case for arrays that need to be converted to strings
            if let arrayValue = value as? [String] {
                let jsonString = try? JSONSerialization.data(withJSONObject: arrayValue, options: [])
                if let jsonString = jsonString {
                    astroChartDataEntity.setValue(String(data: jsonString, encoding: .utf8), forKey: key)
                }
            } else {
                astroChartDataEntity.setValue(value, forKey: key)
            }
        }
        
        // Add timestamp
        astroChartDataEntity.setValue(Date(), forKey: "createdAt")
        
        // Save the context
        do {
            try context.save()
            print("✅ AstroChartData saved to CoreData successfully")
        } catch {
            print("❌ Error saving AstroChartData to CoreData: \(error.localizedDescription)")
        }
    }
    
    func saveUserProfileToFirestore(profile: UserProfileEntity, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user.")
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let profileData: [String: Any] = [
            "displayName": profile.displayName ?? "",
            "email": profile.email ?? "",
            "uid": profile.uid ?? currentUser.uid,
            "sun": profile.sun ?? "",
            "sunArchetype": profile.sunArchetype ?? "",
            "moon": profile.moon ?? "",
            "moonArchetype": profile.moonArchetype ?? "",
            "ascendant": profile.ascendant ?? "",
            "ascendantArchetype": profile.ascendantArchetype ?? "",
            "strongestPlanet": profile.strongestPlanet ?? "",
            "strongestPlanetArchetype": profile.strongestPlanetArchetype ?? "",
            "strongestPlanetSignArchetype": profile.strongestPlanetSignArchetype ?? "",
            "strongestAspects": profile.strongestAspects ?? [],
            "bio": profile.bio ?? "",
            "role": profile.role ?? "",
            "latitude": profile.latitude ?? "",
            "longitude": profile.longitude ?? "",
            "birthDate": profile.birthDate ?? "",
        ]

        // Save to Firestore in the "users" collection
        db.collection("users").document(currentUser.uid).setData(profileData) { error in
            if let error = error {
                print("Failed to save user profile to Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User profile saved to Firestore successfully.")
                completion(true)
            }
        }
    }
    // Modified logEvent function with better error handling
    func logEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        print("EVENT LOGGED: \(eventName)")
        if let parameters = parameters {
            print("EVENT PARAMETERS: \(parameters)")
        }
        
        // Save event to CoreData for analytics tracking
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ Error: Could not access AppDelegate")
            return
        }
        
        // Print all available entity names
        let managedObjectModel = appDelegate.persistentContainer.managedObjectModel
        let entityNames = managedObjectModel.entities.map { $0.name ?? "Unknown" }
        print("Available entities in Core Data model: \(entityNames)")
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Check if entity exists before trying to use it
        if let entity = NSEntityDescription.entity(forEntityName: "AnalyticsEventEntity", in: context) {
            let event = NSManagedObject(entity: entity, insertInto: context)
            
            event.setValue(eventName, forKey: "eventName")
            event.setValue(Date(), forKey: "timestamp")
            
            if let parameters = parameters {
                // Convert parameters to JSON string
                if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    event.setValue(jsonString, forKey: "parameters")
                }
            }
            
            do {
                try context.save()
                print("✅ Analytics event saved to CoreData")
            } catch {
                print("❌ Failed to save analytics event: \(error.localizedDescription)")
            }
        } else {
            print("❌ Error: AnalyticsEventEntity not found in Core Data model")
        }
    }
}
import UIKit

protocol OnboardingDelegate: AnyObject {
    func didCompleteOnboarding(with userProfile: UserProfile)
}

import UIKit
import MapKit


class SuggestionsViewController: UIViewController, UITextFieldDelegate, MKLocalSearchCompleterDelegate {

    var autocompleteSuggestions: [MKLocalSearchCompletion] = []
    let searchCompleter = MKLocalSearchCompleter()
    weak var delegate: SuggestionsViewControllerDelegate?

    let customLocations: [String] = [
        "Frankenberg-Eder, Germany",
        "Kesswill, Switzerland",
        "Zundert, Netherlands",
        "Quezon City, Phillipines",
        "Branau, Austria",
        "BOLOTNOJE",
        "Bolotnoje, Russia",
        "Bolotnoye, Russia",
        "Kiskunfelegyhaza, Hungary"
        // Add custom location with correct spelling
    ]

    lazy var placeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Place"
        textField.borderStyle = .roundedRect
        textField.delegate = self
        return textField
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupSearchCompleter()
    }

    func setupViews() {
        view.addSubview(placeTextField)
        view.addSubview(tableView)

        placeTextField.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            placeTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            placeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            placeTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            placeTextField.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: placeTextField.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == placeTextField {
            if let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
                searchCompleter.queryFragment = text
            }
        }
        return true
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let streetIndicators = ["St", "Rd", "Ave", "Ct", "Cir", "Pl", "Dr", "Lane", "Blvd", "Drive", "Way", "Street", "Road", "Avenue", "Court", "Ln", "Boulevard", "Drive", "Terrace", "Place", "Path", "Trail", "Tr", "Trl", "Plaza"]

        autocompleteSuggestions = completer.results.filter { suggestion in
            let components = suggestion.title.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let combined = "\(suggestion.title) \(suggestion.subtitle)"
            if combined.lowercased().contains("aaefsrgetgeg") {
                return false
            } else if components.count == 2 {
                return true
            } else if components.count == 1 {
                let words = components[0].split(separator: " ").map { String($0) }
                return !words.contains(where: { streetIndicators.contains($0) })
            }
            return false
        }
        tableView.reloadData()
    }

    // MARK: - Combine Custom Locations

    func combineSuggestions() -> [String] {
        var combinedSuggestions: [String] = autocompleteSuggestions.map { "\($0.title) \($0.subtitle)" }
        combinedSuggestions.append(contentsOf: customLocations.filter {
            $0.lowercased().contains(placeTextField.text?.lowercased() ?? "")
        })
        return combinedSuggestions
    }

}

extension SuggestionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return combineSuggestions().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let suggestions = combineSuggestions()
        
        cell.textLabel?.text = suggestions[indexPath.row]
        cell.textLabel?.numberOfLines = 1  // Keep to one line
        cell.textLabel?.adjustsFontSizeToFitWidth = true  // This enables auto-shrinking
        cell.textLabel?.minimumScaleFactor = 0.75  // Don't shrink smaller than 75% of the original size
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let suggestions = combineSuggestions()
        let selectedSuggestion = suggestions[indexPath.row]

        if customLocations.contains(selectedSuggestion) {
            delegate?.didSelectPlace(selectedSuggestion)
        } else {
            if let mkSuggestion = autocompleteSuggestions.first(where: { "\($0.title) \($0.subtitle)" == selectedSuggestion }) {
                delegate?.suggestionSelected(mkSuggestion)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

protocol SuggestionsViewControllerDelegate: AnyObject {
    func suggestionSelected(_ suggestion: MKLocalSearchCompletion)
    func didSelectPlace(_ place: String)
}

struct UserProfile {
    let displayName: String
    let sun: String
    let sunArchetype: String
    let moon: String
    let moonArchetype: String
    let ascendant: String
    let ascendantArchetype: String
    let strongestPlanet: String
    let strongestPlanetArchetype: String
    let strongestPlanetSignArchetype: String
    let strongestAspects: String
    let sentenceText: String
    let bio: String
    let email: String
    let uid: String
    let profileImageURL: String?
    let profileImageURL2: String?
    let profileImageURL3: String?
    let profileImageURL4: String?
    let prompt1: String?
    let prompt2: String?
    let prompt3: String?
    let response1: String?
    let response2: String?
    let response3: String?
    let role: String // New property added for user role

    init(data: [String: Any]) {
        self.displayName = data["displayName"] as? String ?? "Unknown"
        self.sun = data["sun"] as? String ?? "Unknown"
        self.sunArchetype = data["sunArchetype"] as? String ?? "Unknown"
        self.moon = data["moon"] as? String ?? "Unknown"
        self.moonArchetype = data["moonArchetype"] as? String ?? "Unknown"
        self.ascendant = data["ascendant"] as? String ?? "Unknown"
        self.ascendantArchetype = data["ascendantArchetype"] as? String ?? "Unknown"
        self.strongestPlanet = data["strongestPlanet"] as? String ?? "Unknown"
        self.strongestPlanetArchetype = data["strongestPlanetArchetype"] as? String ?? "Unknown"
        self.strongestPlanetSignArchetype = data["strongestPlanetSignArchetype"] as? String ?? "Unknown"
        self.strongestAspects = data["strongestAspects"] as? String ?? ""
        self.sentenceText = data["sentenceText"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.uid = data["uid"] as? String ?? "Unknown"
        self.profileImageURL = data["profileImageURL"] as? String
        self.profileImageURL2 = data["profileImageURL2"] as? String
        self.profileImageURL3 = data["profileImageURL3"] as? String
        self.profileImageURL4 = data["profileImageURL4"] as? String
        self.prompt1 = data["prompt1"] as? String
        self.prompt2 = data["prompt2"] as? String
        self.prompt3 = data["prompt3"] as? String
        self.response1 = data["response1"] as? String
        self.response2 = data["response2"] as? String
        self.response3 = data["response3"] as? String
        self.role = data["role"] as? String ?? "user" // Default to "user" if role is not present
    }
}

struct AstroChartData {
    var name: String
   
    var id: UUID
    var sex: String
    var birthplace: String
    var strongestPlanet: String
    var birthMoment: Date
    var planetScore: [String] // Assuming this is an array of formatted strings
    var signScore: [String] // Assuming this is an array of formatted strings
    var houseScore: [String] // Assuming this is an array of formatted strings
    var planetHDScore: [String]
    var signHDScore: [String]
    var housesHDScore: [String]
  
    var dateEntered: Date
    var natalMoonPhase: String

    var dictionaryRepresentation: [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        let birthMomentString = "Date of Birth: \(dateFormatter.string(from: birthMoment))"
        let dateString2 = "Date of input: \(dateFormatter.string(from: Date()))"
        return [
            "name": name,
            "id": id.uuidString,
            "birthplace": birthplace,
            "strongestPlanet": strongestPlanet,
            "birthMoment": birthMomentString,
            "planetScore": planetScore,
            "signScore": signScore,
            "houseScore": houseScore,
            "planetHDScore": planetHDScore,
            "signHDScore": signHDScore,
            "houseHDScore": housesHDScore,
            "dateEntered": dateString2,
    
            "natalMoonPhase": natalMoonPhase,
            "sex": sex
        ]
    }
}

