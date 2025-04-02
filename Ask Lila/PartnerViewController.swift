//
//  PartnerViewController.swift
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

//import GoogleMaps
import CoreLocation
import UniformTypeIdentifiers
import CoreData

struct TimeZoneException {
    let location: String
    let startDate: Date
    let endDate: Date
    let timeZoneIdentifier: String
    let offset: String // "+hh:mm" or "-hh:mm"
}

struct ChartCacheData {
    let strongestPlanet: CelestialObject
    let mostHarmoniousPlanet: CelestialObject
    let mostDiscordantPlanet: CelestialObject
    let planetScores: [CelestialObject: Double]
    let signScores: [Zodiac: Double]
    let houseScores: [Int: Double]
    let harmonyDiscordNetScores: [CelestialObject: (harmony: Double, discord: Double, netHarmony: Double)]
    let strongestPlanetSign: String
}

public enum Subcategory: String {
    
    case artists = "Artists"
    case actors = "Actors"
    case musicians = "Musicians"
    case in_the_news = "In the News"
    case scientists_innovators = "Scientists"
    case athletes_soldiers = "Athletes/Soldiers"
    case spiritual_figures = "Spiritual Figures"
    case political_figures = "Political Figures"

}
public enum Category: String {
    case family = "Family"
    case friend = "Friend"
//    case child = "Child"
    case rando = "Rando"
    case famous = "Famous"

}
var category: Category = .friend // Default to male

class PartnerViewController: UIViewController,  SuggestionsViewControllerDelegate, MKLocalSearchCompleterDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIDocumentPickerDelegate  {
    var motherChart: Chart? // Store mother chart data
      var fatherChart: Chart? // Store father chart data

    var onProfileCompletion: (() -> Void)?
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
    //   var aspects: [AstroAspect?] = []
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
    var sex: Sex = .male
    var category: Category = .friend // Default to male
    var subCategory: Subcategory? // ✅ Make it optional

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
        textField.placeholder = "Name"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
     //   textField.frame = CGRect(x: 50, y: 200, width: 300, height: 45)  // Adjust y to position it above dateTextField
        return textField
    }()
    var selectedSubcategory: String?
    lazy var birthPlaceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Place of Birth"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
     //   textField.frame = CGRect(x: 50, y: 260, width: 300, height: 45)
        textField.addTarget(self, action: #selector(birthPlaceTextFieldEditingDidBegin), for: .editingDidBegin)
        return textField
    }()

    // Main category control
    // Update the categorySegmentedControl to include "Child"
    lazy var categorySegmentedControl: UISegmentedControl = {
        let items = ["Fam", "Friend","Rando", "Famous"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 1 // Default to Friend
        segmentedControl.addTarget(self, action: #selector(categorySegmentedControlChanged(_:)), for: .valueChanged)
        return segmentedControl
    }()


    // UIPickerView for Famous subcategories
    lazy var subcategoryPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.isHidden = true // Initially hidden
        return picker
    }()

    // Subcategories for "Famous"
    let famousSubcategories = ["Artists","Actors","Musicians","In the News","Scientists/Innovators", "Athletes/Soldiers", "Spiritual Figures", "Political Figures"]


      lazy var sexSegmentedControl: UISegmentedControl = {
          let items = ["Male", "Female"]
          let segmentedControl = UISegmentedControl(items: items)
          segmentedControl.selectedSegmentIndex = 0 // Default to Male
          segmentedControl.addTarget(self, action: #selector(sexSegmentedControlChanged(_:)), for: .valueChanged)
          return segmentedControl
      }()

    var subcategory: String?
    lazy var dateTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Date of Birth"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
   //     textField.frame = CGRect(x: 50, y: 320, width: 300, height: 45)

        return textField
    }()


    lazy var birthTimeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Time of Birth"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.textAlignment = .center // This centers the text horizontally
        textField.borderStyle = .roundedRect
//textField.frame = CGRect(x: 50, y: 380, width: 300, height: 45)
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
        button.setTitle("Save Chart?", for: .normal)
        button.addTarget(self, action: #selector(getPowerPlanetButtonTapped), for: .touchUpInside)

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


            searchCompleter.delegate = self
            birthPlaceTextField.delegate = self
            view.backgroundColor = UIColor(red: 236/255, green: 239/255, blue: 244/255, alpha: 1)

            // Set up navigation bar back button
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                style: .plain,
                target: self,
                action: #selector(navigateBackToCharts)
            )
            navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1) // Lavender tint

            // Set up Import Button in Navigation Bar
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "tray.and.arrow.down"),
                style: .plain,
                target: self,
                action: #selector(presentImportOptions)
            )
            navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1) // Lavender tint

            // Title styling
            let titleLabel = UILabel()
            titleLabel.text = "Create or Import a New Chart ☿"
            titleLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)
            titleLabel.font = UIFont(name: "Chalkduster", size: 15) ?? UIFont.systemFont(ofSize: 20)
            navigationItem.titleView = titleLabel


        searchCompleter.delegate = self
        birthPlaceTextField.delegate = self

        view.backgroundColor = UIColor(red: 236/255, green: 239/255, blue: 244/255, alpha: 1) // Light grey background for a clean look.


        let backButton = UIButton(type: .system)
        // Use the system back arrow image
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)
        backButton.addTarget(self, action: #selector(navigateBackToCharts), for: .touchUpInside)

        // Set the frame or constraints for the back button
        backButton.frame = CGRect(x: 5, y:  20, width: 40, height: 30) // Adjust the size and position as needed
        view.addSubview(backButton)

        // Set up Import Button
        let importButton = UIButton(type: .custom)
        importButton.setImage(UIImage(systemName: "tray.and.arrow.down"), for: .normal) // Use appropriate system image
        importButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)  // Lavender color
        importButton.addTarget(self, action: #selector(presentImportOptions), for: .touchUpInside)

        // Adjust the frame for the Import button
        let buttonX = view.bounds.width - 50 // Adjust as needed
        importButton.frame = CGRect(x: buttonX, y: 20, width: 40, height: 40)

        view.addSubview(titleLabel)
        view.addSubview(importButton)

//        // Create the title label
//        let titleLabel = UILabel(frame: CGRect(x: 15, y: headerView.bounds.height - 50, width: view.bounds.width - 80, height: 40))
//        titleLabel.text = "Astrologic ☿"
//        titleLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1)
//        titleLabel.font = UIFont(name: "Chalkduster", size: 30) ?? UIFont.systemFont(ofSize: 20)
//        headerView.addSubview(titleLabel)



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
        view.addSubview(categorySegmentedControl)
        categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subcategoryPicker)
        subcategoryPicker.translatesAutoresizingMaskIntoConstraints = false
               view.addSubview(sexSegmentedControl)
               sexSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
               
               NSLayoutConstraint.activate([
                   nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                   nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
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

                   categorySegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                   categorySegmentedControl.topAnchor.constraint(equalTo: sexSegmentedControl.bottomAnchor, constant: 20),
                   categorySegmentedControl.widthAnchor.constraint(equalToConstant: 300),
                   categorySegmentedControl.heightAnchor.constraint(equalToConstant: 45),

                   // Layout for subcategoryPicker (hidden by default)
                     subcategoryPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                     subcategoryPicker.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 20),
                     subcategoryPicker.widthAnchor.constraint(equalToConstant: 300),
                     subcategoryPicker.heightAnchor.constraint(equalToConstant: 150),


                   getPowerPlanetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                   getPowerPlanetButton.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 30),
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


      // getPowerPlanetButton.frame = CGRect(x: 50, y: 440, width: 300, height: 45)
       // parseAndSaveData()
        view.addSubview(getPowerPlanetButton)

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()


        setupSexSegmentedControl() // Call this to set up the segmented control

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

    // MARK: - Time Zone Adjustment

    private func adjustDateForTimeZone(_ date: Date, to timeZone: TimeZone) -> Date {
        let secondsFromGMT = timeZone.secondsFromGMT(for: date)
        return Date(timeInterval: TimeInterval(secondsFromGMT), since: date)
    }

    @objc func categorySegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            category = .family
            subCategory = nil // ✅ Now allowed because it's optional
            subcategoryPicker.isHidden = true
        case 1:
            category = .friend
            subCategory = nil
            subcategoryPicker.isHidden = true
        case 2:
            category = .rando
            subCategory = nil
            subcategoryPicker.isHidden = true
        case 3:
            category = .famous
            subcategoryPicker.isHidden = false
            if let firstSubcategory = famousSubcategories.first {
                subCategory = Subcategory(rawValue: firstSubcategory) // ✅ Convert String to Subcategory
            }
        default:
            break
        }
        print("DEBUG: Selected category -> \(category.rawValue), Subcategory -> \(subCategory?.rawValue ?? "None")")
    }





    // PickerView delegate and data source methods for subcategories
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return famousSubcategories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return famousSubcategories[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        subcategory = famousSubcategories[row]
        print("Selected subcategory: \(subcategory ?? "")")
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

    func setupCategorySegmentedControl() {
        // Add target-action for the segmented control
        categorySegmentedControl.addTarget(self, action: #selector(categorySegmentedControlChanged(_:)), for: .valueChanged)

        // Set default selection
        categorySegmentedControl.selectedSegmentIndex = 1 // Default to male
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

//
//    @objc func showMyCharts() {
//        let myChartsViewController = ChartsViewController() // Assuming it's a basic table view
//        Analytics.logEvent("tapped_chart_folder", parameters: nil
//        )
//
//
//
//
//        navigationController?.pushViewController(myChartsViewController, animated: true)
//    }



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



    @objc private func presentAAFFilePicker() {
          if #available(iOS 14.0, *) {
              // Modern API for iOS 14+
              let aafType: UTType = (try? UTType(filenameExtension: "aaf")) ?? .text
              let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [aafType])
              documentPicker.delegate = self
              present(documentPicker, animated: true, completion: nil)
          } else {
              // Fallback for iOS 13 and earlier
              let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text", "com.errick.astrologic.aaf"], in: .import)
              documentPicker.delegate = self
              present(documentPicker, animated: true, completion: nil)
          }
      }

      // MARK: - UIDocumentPickerDelegate
      func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
          guard let fileURL = urls.first else { return }
          do {
              let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
              print("File contents: \(fileContents)")
              // Handle parsing and saving the file data here
          } catch {
              print("Error reading file: \(error.localizedDescription)")
          }
      }

      func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
          print("Document picker was cancelled.")
      }
    
    @objc private func navigateBackToCharts() {
        navigationController?.popViewController(animated: true) // Navigate back to ChartsViewController
    }



    func fetchAllCharts(completion: @escaping ([ChartEntity]) -> Void) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request: NSFetchRequest<ChartEntity> = ChartEntity.fetchRequest()
        
        do {
            let charts = try context.fetch(request)
            print("📦 DEBUG: Found \(charts.count) total charts")
            for chart in charts {
                print("🔍 Chart: \(chart.name ?? "Unnamed")")
            }
            completion(charts)
        } catch {
            print("❌ ERROR fetching charts: \(error.localizedDescription)")
            completion([])
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



}

extension PartnerViewController: CLLocationManagerDelegate {

    private func saveChartToCoreData(chartCake: ChartCake) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Unable to get AppDelegate")
            return
        }

        let context = appDelegate.persistentContainer.viewContext

        guard let newChartEntity = NSEntityDescription.insertNewObject(forEntityName: "ChartEntity", into: context) as? ChartEntity else {
            print("Failed to create a new ChartEntity")
            return
        }

        // Populate ChartEntity with ChartCake and parsed data
        newChartEntity.name = chartCake.name
        newChartEntity.birthDate = chartCake.natal.birthDate
        newChartEntity.latitude = chartCake.natal.latitude
        newChartEntity.longitude = chartCake.natal.longitude
        newChartEntity.birthPlace = chartCake.name
     //   newChartEntity.timeZoneIdentifier = timeZoneIdentifier
        newChartEntity.sex = sex.rawValue
        // Add this to your saveChartToCoreData function before saving
        newChartEntity.chartID = UUID().uuidString
        do {
            try context.save()
            print("Chart saved successfully in Core Data")
            print("✅ SAVED: \(chartCake.name) at \(chartCake.natal.birthDate) with ID: \(newChartEntity.chartID ?? "Unknown")")

        } catch {
            print("Failed to save ChartEntity to Core Data: \(error.localizedDescription)")
        }
    }

    // MARK: - Core Data Functions to Replace Firebase

 

//  
//    // Replace the saveChart function to use Core Data only
//    func saveChart(
//        name: String,
//        birthDate: Date,
//        latitude: Double,
//        longitude: Double,
//        birthPlace: String,
//        strongestPlanet: String,
//        sex: String,
//        mostHarmoniousPlanet: String,
//        mostDiscordantPlanet: String,
//        sentenceText: String,
//        strongestPlanetSign: String,
//        strongestPlanetArchetype: String,
//        timeZoneIdentifier: String,
//        category: String? = nil,
//        subCategory: String? = nil,
//        chartID: String? = nil,
//        dateAdded: Date? = nil
//    ) {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
//            print("❌ ERROR: Unable to get AppDelegate")
//            return
//        }
//
//        let context = appDelegate.persistentContainer.viewContext
//
//        guard let newChartEntity = NSEntityDescription.insertNewObject(forEntityName: "ChartEntity", into: context) as? ChartEntity else {
//            print("❌ ERROR: Failed to create a new ChartEntity")
//            return
//        }
//
//        // ✅ Assign values to Core Data entity
//        newChartEntity.name = name
//        newChartEntity.birthDate = birthDate
//        newChartEntity.latitude = latitude
//        newChartEntity.longitude = longitude
//        newChartEntity.birthPlace = birthPlace
//        newChartEntity.strongestPlanet = strongestPlanet
//        newChartEntity.sex = sex
//        newChartEntity.mostHarmoniousPlanet = mostHarmoniousPlanet
//        newChartEntity.mostDiscordantPlanet = mostDiscordantPlanet
//        newChartEntity.sentenceText = sentenceText
//        newChartEntity.strongestPlanetSign = strongestPlanetSign
//        newChartEntity.strongestPlanetArchetype = strongestPlanetArchetype
//        newChartEntity.timeZoneIdentifier = timeZoneIdentifier
//        newChartEntity.dateAdded = dateAdded ?? Date() // Default to current date if nil
//
//        // ✅ Store category and subcategory in Core Data
//        newChartEntity.category = category
//        newChartEntity.subCategory = subCategory
//        
//        // Generate a UUID if not provided
//        if let chartID = chartID {
//            newChartEntity.chartID = chartID
//        } else {
//            newChartEntity.chartID = UUID().uuidString
//        }
//
//        // ✅ Debug Print Before Saving
//        print("🔹 DEBUG: Saving chart...")
//        print("   📅 Date Added: \(newChartEntity.dateAdded ?? Date())")
//        print("   📂 Category: \(newChartEntity.category ?? "None")")
//        print("   🎭 Subcategory: \(newChartEntity.subCategory ?? "None")")
//        
//        // Associate with user if logged in
//        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
//            newChartEntity.id = userId
//            
//            // Fetch the user entity to establish relationship
//            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
//            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
//            
//            do {
//                let results = try context.fetch(fetchRequest)
//                if let userEntity = results.first {
//                    // Set the relationship bidirectionally
//                    newChartEntity.user = userEntity
//                    userEntity.mutableSetValue(forKey: "charts").add(newChartEntity)
//                }
//            } catch {
//                print("Error fetching user entity: \(error.localizedDescription)")
//            }
//        }
//
//        do {
//            try context.save()
//            print("✅ SUCCESS: Chart saved successfully in Core Data")
//            print("✅ SAVED: \(name) at \(birthDate) with ID: \(newChartEntity.chartID ?? "Unknown")")
//
////            // Create and save the AstroChartData if needed
////            if let chartCake = self.chartCake {
////                let astroChartData = self.createAstroChartData(chartCake: chartCake, name: name, id: UUID(uuidString: newChartEntity.chartID ?? "") ?? UUID())
////                let astroChartDictionary = astroChartData.dictionaryRepresentation
////                self.saveAstroChartDataToCoreData(data: astroChartDictionary)
////            }
////            
//            // Log event using local analytics
//            self.logEvent("chart_created", parameters: [
//                "name": name,
//                "category": category ?? "Unknown",
//                "subcategory": subCategory ?? "None",
//                "sex": sex
//            ])
//        } catch {
//            print("❌ ERROR: Failed to save ChartEntity to Core Data: \(error.localizedDescription)")
//        }
//    }
//    
   
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

    // Modify the getPowerPlanetButtonTapped method to replace Firebase calls
    @objc func getPowerPlanetButtonTapped() {
        print("DEBUG: Sex before saving -> \(sex.rawValue)")

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

        getPowerPlanetButton.isEnabled = false
        // Replace Firebase Analytics with Core Data logging
        logEvent("chart_added")

        let location = birthPlaceTextField.text!
        // Usage inside your geocoding completion
        geocoding(location: location) { latitude, longitude in
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            getTimeZone(location: coordinate) { [weak self] timeZone in
                guard let self = self, let timeZone = timeZone else { return }
                
                // Adjust for LMT if needed
                let adjustedTimeZoneIdentifier = self.adjustForTimeZoneException(
                    date: self.datePicker.date,
                    location: location,
                    latitude: latitude,
                    longitude: longitude,
                    geocodedTimeZoneIdentifier: timeZone.identifier
                )
                
                // If adjusted to LMT, calculate LMT based on longitude
                let adjustedTimeZone: TimeZone
                if adjustedTimeZoneIdentifier == "LMT" {
                    adjustedTimeZone = self.calculateLMT(longitude: longitude)
                } else {
                    adjustedTimeZone = TimeZone(identifier: adjustedTimeZoneIdentifier) ?? timeZone
                }
                
                // Apply the calculated or geocoded timezone
                self.timePicker.timeZone = adjustedTimeZone
                self.datePicker.timeZone = adjustedTimeZone
                birthPlaceTimeZone = adjustedTimeZone
                
                func combinedDateAndTime() -> Date? {
                    let calendar = Calendar.current
                    
                    // Make sure you're setting the timeZone for your pickers somewhere in your code, every time you're about to use them
                    datePicker.timeZone = adjustedTimeZone
                    timePicker.timeZone = adjustedTimeZone
                    birthPlaceTimeZone = adjustedTimeZone
                    
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: datePicker.date)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)
                    
                    dateComponents.timeZone = birthPlaceTimeZone
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    guard let combinedDate = calendar.date(from: dateComponents) else {
                        print("Failed to combine date and time components")
                        return nil
                    }
                    
                    // Logging the final combined date and time
                    print("Using combined date and time for chart: \(combinedDate) in timezone: \(birthPlaceTimeZone!.identifier)")
                    return combinedDate
                }
                
                let chartDate = combinedDateAndTime()!
     let selectedDate = selectedDate ?? Date()
                self.chartCake = ChartCake(birthDate: chartDate, latitude: latitude, longitude: longitude, transitDate: selectedDate, name: nameTextField.text)
                
                guard let chartCake = self.chartCake else {
                    assert(false, "There is no chart")
                    return
                }
                
                // Attach the parent's charts (previously captured)
              
                
                let name = nameTextField.text ?? ""
                let id = chartCake.id
                
                // Process chart data
                let scores = chartCake.planetScoresSN
                let mostDiscordantPlanet = chartCake.mostDiscordantPlanetSN
                let mostHarmoniousPlanet = chartCake.mostHarmoniousPlanetSN
                let strongestPlanet = chartCake.getStrongestPlanet(from: scores)
                
                // Determine the strongest planet sign
                if strongestPlanet == Planet.sun.celestialObject {
                    strongestPlanetSign = chartCake.natal.sun.sign.keyName
                } else if strongestPlanet == Planet.moon.celestialObject {
                    strongestPlanetSign = chartCake.natal.moon.sign.keyName
                } else if strongestPlanet == Planet.mercury.celestialObject {
                    strongestPlanetSign = chartCake.natal.mercury.sign.keyName
                } else if strongestPlanet == Planet.venus.celestialObject {
                    strongestPlanetSign = chartCake.natal.venus.sign.keyName
                } else if strongestPlanet == Planet.mars.celestialObject {
                    strongestPlanetSign = chartCake.natal.mars.sign.keyName
                } else if strongestPlanet == Planet.jupiter.celestialObject {
                    strongestPlanetSign = chartCake.natal.saturn.sign.keyName
                } else if strongestPlanet == Planet.uranus.celestialObject {
                    strongestPlanetSign = chartCake.natal.uranus.sign.keyName
                } else if strongestPlanet == Planet.neptune.celestialObject {
                    strongestPlanetSign = chartCake.natal.neptune.sign.keyName
                } else if strongestPlanet == Planet.pluto.celestialObject {
                    strongestPlanetSign = chartCake.natal.pluto.sign.keyName
                } else if strongestPlanet == LunarNode.meanSouthNode.celestialObject {
                    strongestPlanetSign = chartCake.natal.southNode.sign.keyName
                } else if strongestPlanet == chartCake.natal.ascendantCoordinate.body {
                    strongestPlanetSign = "ac"
                } else if strongestPlanet == chartCake.natal.ascendantCoordinate.body {
                    strongestPlanetSign = "mc"
                }
                
                print("SEX: \(chartCake.sex.rawValue)")
                print("Category: \(chartCake.category.rawValue)")
                print("SubCategory: \(chartCake.subCategory.rawValue)")
                
                let sentence = generateAstroSentence(
                    strongestPlanet: strongestPlanet.keyName,
                    strongestPlanetSign: chartCake.strongestPlanetSign.keyName,
                    sunSign: chartCake.natal.sun.sign.keyName,
                    moonSign: chartCake.natal.moon.sign.keyName,
                    risingSign: chartCake.natal.houseCusps.ascendent.sign.keyName,
                    name: name
                )
                
                // Save chart to Core Data
                saveChartToCoreData(chartCake: chartCake)
                
          
                // Check if we're in "add partner" mode by looking at the title
                if self.title == "Add Partner Chart" {
                    // This is a partner chart addition flow
                    print("✅ Partner chart added successfully: \(name)")
                    
                    // Reset the input fields
                    DispatchQueue.main.async {
                        self.resetDateAndTimePickers()
                        self.resetViewController()
                        self.nameTextField.text = ""
                        self.birthPlaceTextField.text = ""
                        self.dateTextField.text = ""
                        self.birthTimeTextField.text = ""
                        
                        // Call the completion handler if it exists
                        if let completion = self.onProfileCompletion {
                            // Dismiss the view controller and execute the completion handler
                            self.navigationController?.dismiss(animated: true) {
                                completion()
                            }
                        } else {
                            // Just dismiss if no completion handler
                            self.navigationController?.dismiss(animated: true)
                        }
                        
                        self.getPowerPlanetButton.isEnabled = true
                    }
                } else {
                    // This is the normal flow - just dismiss or proceed with any other logic
                    DispatchQueue.main.async {
                        // Reset input fields
                        self.resetDateAndTimePickers()
                        self.resetViewController()
                        self.nameTextField.text = ""
                        self.birthPlaceTextField.text = ""
                        self.dateTextField.text = ""
                        self.birthTimeTextField.text = ""
                        
                        // Set button back to enabled state
                        self.getPowerPlanetButton.isEnabled = true
                        
                        // Notify that chart was created successfully
                        self.showAlert(withTitle: "Success", message: "Chart created successfully!")
                    }
                }
            }
        } failure: { msg in
            // Also enable the button when there's a failure in geocoding
            DispatchQueue.main.async {
                self.getPowerPlanetButton.isEnabled = true
                self.showAlert(withTitle: "Error", message: "Failed to geocode location: \(msg)")
            }
        }
    }
   
    // Helper method to create AstroChartData
    private func createAstroChartData(chartCake: ChartCake, name: String, id: UUID) -> AstroChartData {
        let natalMoonPhase = chartCake.lunarPhase(for: chartCake.transits)
        let scores = chartCake.planetScoresSN
        let signScores = chartCake.signScoresSN
        let houseScores = chartCake.houseScoresSN
        
        let planetPercentages = formattedPlanetScores(scores)
        let signPercentages = formattedSignScores(signScores)
        let housePercentages = formattedHouseScores(houseScores)
        
        let harmonyDiscordNetScores = chartCake.planetHarmonyDiscordSN
        let formattedScores = formattedHarmonyDiscordNetScores(harmonyDiscordNetScores)
        
        let signHarmonyDiscordScores = chartCake.signHarmonyScoresSN
        let signHarmonyDiscordFormattedSignScores = formattedSignHarmonyDiscordScores(signHarmonyDiscordScores)
        
        let houseHarmonyDiscordScores = chartCake.houseHarmonyScoresSN
        let HouseHDformattedHouseScores = formattedHouseHarmonyDiscordScores(houseHarmonyDiscordScores)
        
        return AstroChartData(
            name: name,
            id: id,
            sex: sex.rawValue,
            birthplace: birthPlaceTextField.text ?? "",
            strongestPlanet: chartCake.getStrongestPlanet(from: scores).keyName,
            birthMoment: chartCake.natal.birthDate,
            planetScore: planetPercentages,
            signScore: signPercentages,
            houseScore: housePercentages,
            planetHDScore: formattedScores,
            signHDScore: signHarmonyDiscordFormattedSignScores,
            housesHDScore: HouseHDformattedHouseScores,
            dateEntered: Date(),
            natalMoonPhase: natalMoonPhase.rawValue
        )
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

    


    func resetViewController() {
        // Clear input fields
        birthPlaceTextField.text = ""
        datePicker.setDate(Date(), animated: true)

        // Get the text from the birthPlaceTextField
        if let birthPlace = birthPlaceTextField.text {
            // Use the text to determine the time zone identifier
            let timeZone = TimeZone(identifier: birthPlace)

            // Set the timeZone property of the UIDatePicker
            timePicker.timeZone = timeZone


            func resetViewController() {
                birthPlaceTextField.text = ""
                nameTextField.text = ""
                datePicker.setDate(Date(), animated: true)
                timePicker.setDate(Date(), animated: true)

                // Reset the time zone of the UIDatePicker based on the input in the birthPlaceTextField
                if let birthPlace = birthPlaceTextField.text,
                   let timeZone = TimeZone(identifier: birthPlace) {
                    timePicker.timeZone = timeZone
                }

                // Reset any other components to their initial state
                // ...
            }

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
        present(alert, animated: true, completion: nil
        ) }


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
    @objc private func presentImportOptions() {
        let alertController = UIAlertController(
            title: "Import Chart",
            message: "Choose how to import your chart.",
            preferredStyle: .actionSheet
        )

        // Define import options
        let options: [(String, UIAlertAction.Style, (() -> Void)?)] = [
            // Option 1: Import AAF File
            ("Import AAF File", .default, { [weak self] in
                self?.presentAAFFilePicker()
            }),

            // Option 2: Paste Single AAF Text
            ("Paste Single AAF Text", .default, {
                self.pasteSingleAAFText()
            }),

            // Option 3: Paste Multiple AAF Texts
            ("Paste Multiple AAF Texts", .default, {
                self.pasteMultipleAAFTexts()
            }),

            // Cancel Option
            ("Cancel", .cancel, nil)
        ]

        // Add actions to alertController
        options.forEach { title, style, handler in
            alertController.addAction(UIAlertAction(title: title, style: style) { _ in
                handler?()
            })
        }

        // Present the action sheet
        present(alertController, animated: true)
    }

    private func pasteSingleAAFText() {
        let alertController = UIAlertController(
            title: "Paste Single AAF Text",
            message: "Paste a single AAF entry below.",
            preferredStyle: .alert
        )

        // Add a text field for input
        alertController.addTextField { textField in
            textField.placeholder = "Enter AAF text here..."
            textField.keyboardType = .default
        }

        // Add actions
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Import", style: .default, handler: { _ in
            guard let input = alertController.textFields?.first?.text, !input.isEmpty else { return }
            guard let chartCake = self.chartCake else {
                return
            }
            // Parse the AAF text using ChartCake
            if let parsedData = chartCake.parseAAFDataFromAAF(aafData: input) {
                chartCake.createChartCakeFromAAF(from: parsedData) { chartCake in
                    guard let chartCake = chartCake else {
                        print("Failed to create ChartCake.")
                        return
                    }
                    print("Successfully created ChartCake: \(chartCake.name)")
                    // Save or display the chartCake here
                }
            } else {
                print("Failed to parse AAF text.")
            }
        }))

        present(alertController, animated: true)
    }
    private func pasteMultipleAAFTexts() {
        let alertController = UIAlertController(
            title: "Paste Multiple AAF Texts",
            message: "Paste multiple AAF entries separated by blank lines below.",
            preferredStyle: .alert
        )

        // Add a text field for input
        alertController.addTextField { textField in
            textField.placeholder = "Enter multiple AAF texts here..."
            textField.keyboardType = .default
        }

        // Add actions
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Import", style: .default, handler: { _ in
            guard let input = alertController.textFields?.first?.text, !input.isEmpty else { return }

            // Split the AAF text entries and process each
            let aafEntries = input.components(separatedBy: "\n\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            var chartCakes: [ChartCake] = []
            guard let chartCake = self.chartCake else {
                return
            }
            // DispatchGroup to wait for all async operations
            let group = DispatchGroup()

            aafEntries.forEach { entry in
                group.enter()
                if let parsedData = chartCake.parseAAFDataFromAAF(aafData: entry) {
                    chartCake.createChartCakeFromAAF(from: parsedData) { chartCake in
                        if let chartCake = chartCake {
                            chartCakes.append(chartCake)
                            print("Created ChartCake: \(chartCake.name)")
                        } else {
                            print("Failed to create ChartCake for entry: \(entry)")
                        }
                        group.leave()
                    }
                } else {
                    print("Failed to parse AAF entry: \(entry)")
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                print("Finished importing \(chartCakes.count) charts.")
                // Handle the created chartCakes (e.g., save or display)
            }
        }))

        present(alertController, animated: true)
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

}


