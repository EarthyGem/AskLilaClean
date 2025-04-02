//
//  EditChart.swift
//  Ask Lila
//
//  Created by Errick Williams on 3/17/25.
//

import Foundation
import Foundation
import SwiftEphemeris
import UIKit
import CoreData
import MapKit

protocol EditChartViewControllerDelegate: AnyObject {
    func didUpdateChart(birthDate: Date, latitude: Double, longitude: Double, name: String)
}

class EditChartViewController: UIViewController, SuggestionsViewControllerDelegate, MKLocalSearchCompleterDelegate, UITextFieldDelegate {

    var formattedDateString: String?
    var chartCake: ChartCake?
    let searchCompleter = MKLocalSearchCompleter()
    var suggestions: [MKLocalSearchCompletion] = []
    var searchRequest: MKLocalSearch.Request?
    var autocompleteSuggestions: [String] = []
    weak var delegate: EditChartViewControllerDelegate?

    let nameTextField = UITextField()
    let birthPlaceTextField = UITextField()
    let dateTimeTextField = UITextField()
    let saveButton = UIButton(type: .system)
    let dateTimePicker = UIDatePicker()
    let sexSegmentedControl = UISegmentedControl(items: ["XY", "XX"])

    var birthTimeZone: TimeZone?
    var latitude: Double = 0.0
    var longitude: Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Birth Chart"

        setupTextFields()
        setupDatePicker()
        setupSaveButton()
        setupSexSegmentedControl()
        setupLayout()

        if let chart = chartCake {
            populateFields(with: chart)
        }

        birthPlaceTextField.addTarget(self, action: #selector(birthPlaceTextFieldEditingDidBegin), for: .editingDidBegin)
        searchCompleter.delegate = self
        birthPlaceTextField.delegate = self
    }

    func setupTextFields() {
        nameTextField.borderStyle = .roundedRect
        nameTextField.placeholder = "Name"

        birthPlaceTextField.borderStyle = .roundedRect
        birthPlaceTextField.placeholder = "Birth Place"

        dateTimeTextField.borderStyle = .roundedRect
        dateTimeTextField.placeholder = "Birth Time"
        dateTimeTextField.inputView = dateTimePicker

        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        let doneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dateTimePickerDonePressed))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([flexibleSpace, doneBtn], animated: true)
        toolBar.barTintColor = .lightGray
        doneBtn.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.blue], for: .normal)
        dateTimeTextField.inputAccessoryView = toolBar
    }

    func setupDatePicker() {
        dateTimePicker.datePickerMode = .dateAndTime
        dateTimePicker.preferredDatePickerStyle = .automatic
        dateTimePicker.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)


        dateTimePicker.addTarget(self, action: #selector(dateTimePickerValueChanged(_:)), for: .valueChanged)
    }

    func setupSaveButton() {
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1)
        saveButton.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.75, alpha: 1), for: .normal)
        saveButton.layer.cornerRadius = 8.0
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
    }

    func setupSexSegmentedControl() {
        sexSegmentedControl.selectedSegmentIndex = 0 // Default to Male
        view.addSubview(sexSegmentedControl)
        sexSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupLayout() {
        view.addSubview(nameTextField)
        view.addSubview(birthPlaceTextField)
        view.addSubview(dateTimeTextField)
        view.addSubview(saveButton)
        view.addSubview(sexSegmentedControl)
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        birthPlaceTextField.translatesAutoresizingMaskIntoConstraints = false
        dateTimeTextField.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        sexSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            birthPlaceTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            birthPlaceTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            birthPlaceTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            birthPlaceTextField.heightAnchor.constraint(equalToConstant: 44),
            
            dateTimeTextField.topAnchor.constraint(equalTo: birthPlaceTextField.bottomAnchor, constant: 20),
            dateTimeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateTimeTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dateTimeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            sexSegmentedControl.topAnchor.constraint(equalTo: dateTimeTextField.bottomAnchor, constant: 20),
            sexSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sexSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sexSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: sexSegmentedControl.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func populateFields(with chart: ChartCake) {
        nameTextField.text = chart.name
        
        // For birthplace, we'll need to do a reverse geocode
        reverseGeocode(latitude: chart.natal.latitude, longitude: chart.natal.longitude) { [weak self] placemark in
            guard let self = self else { return }
            
            if let locality = placemark?.locality, let country = placemark?.country {
                self.birthPlaceTextField.text = "\(locality), \(country)"
            } else {
                self.birthPlaceTextField.text = "Unknown Location"
            }
        }
        
        self.latitude = chart.natal.latitude
        self.longitude = chart.natal.longitude
        
        // Set sex based on existing data if available
        // This would need to be stored in the ChartCake or retrieved separately
        
        // Format and display the birth date and time
        fetchTimeZone(latitude: chart.natal.latitude, longitude: chart.natal.longitude) { [weak self] timeZone in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let fetchedTimeZone = timeZone ?? TimeZone.current
                self.birthTimeZone = fetchedTimeZone
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                dateFormatter.timeZone = fetchedTimeZone
                
                let formattedDate = dateFormatter.string(from: chart.natal.birthDate)
                self.dateTimeTextField.text = formattedDate
                
                self.dateTimePicker.timeZone = fetchedTimeZone
                self.dateTimePicker.date = chart.natal.birthDate
            }
        }
    }

    @objc func dateTimePickerDonePressed() {
        updateDateTimeTextField()
        dateTimeTextField.resignFirstResponder()
    }

    @objc func dateTimePickerValueChanged(_ sender: UIDatePicker) {
        updateDateTimeTextField()
    }

    func updateDateTimeTextField() {
        let timeZone = birthTimeZone ?? TimeZone.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = timeZone

        let formattedDate = dateFormatter.string(from: dateTimePicker.date)
        print("🕒 Updated text field with date: \(formattedDate) in TZ: \(timeZone.identifier)")
        dateTimeTextField.text = formattedDate
    }

    
    func reverseGeocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocode error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            completion(placemarks?.first)
        }
    }

    func suggestionSelected(_ suggestion: MKLocalSearchCompletion) {
        // Set the text field to the selected suggestion
        if !suggestion.subtitle.isEmpty {
            birthPlaceTextField.text = "\(suggestion.title), \(suggestion.subtitle)"
        } else {
            birthPlaceTextField.text = suggestion.title
        }
        
        // Geocode the selected place to get coordinates
        geocodeBirthPlace(suggestion: suggestion)
    }
    
    func geocodeBirthPlace(suggestion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = suggestion.title

        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error in geocoding: \(error.localizedDescription)")
                return
            }

            if let item = response?.mapItems.first {
                let coordinate = item.placemark.coordinate
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude

                self.fetchTimeZone(latitude: coordinate.latitude, longitude: coordinate.longitude) { timeZone in
                    guard let newTimeZone = timeZone else {
                        print("Failed to get timezone, falling back to current")
                        return
                    }

                    let oldTimeZone = self.dateTimePicker.timeZone ?? TimeZone.current
                    let currentDate = self.dateTimePicker.date
                    let timeIntervalAdjustment = TimeInterval(newTimeZone.secondsFromGMT(for: currentDate) - oldTimeZone.secondsFromGMT(for: currentDate))
                    let adjustedDate = currentDate.addingTimeInterval(timeIntervalAdjustment)

                    DispatchQueue.main.async {
                        self.birthTimeZone = newTimeZone
                        self.dateTimePicker.timeZone = newTimeZone
                        self.dateTimePicker.date = adjustedDate
                        self.updateDateTimeTextField()  // ✅ This needs to be here after both updates
                    }
                }
            }
        }
    }
    func fetchTimeZone(latitude: Double, longitude: Double, completion: @escaping (TimeZone?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error fetching time zone: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first, let timeZone = placemark.timeZone {
                completion(timeZone)
            } else {
                completion(nil)
            }
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
        
        if let suggestionsVC = presentedViewController as? SuggestionsViewController {
            suggestionsVC.autocompleteSuggestions = suggestions
            suggestionsVC.tableView.reloadData()
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error: \(error.localizedDescription)")
    }

    func didSelectPlace(_ place: String) {
        birthPlaceTextField.text = place
    }

    @objc func birthPlaceTextFieldEditingDidBegin() {
        let suggestionsVC = SuggestionsViewController()
        suggestionsVC.delegate = self
        present(suggestionsVC, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == birthPlaceTextField {
            let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
            searchCompleter.queryFragment = text ?? ""
        }
        return true
    }
   

    @objc func saveChanges() {
        guard !nameTextField.text!.isEmpty,
              !birthPlaceTextField.text!.isEmpty,
              !dateTimeTextField.text!.isEmpty else {
            let alert = UIAlertController(title: "Incomplete Information", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let name = nameTextField.text!
        let birthDate = dateTimePicker.date
        let sex: Sex = sexSegmentedControl.selectedSegmentIndex == 0 ? .male : .female

        // 1. Recreate ChartCake with updated info
        guard let timeZone = birthTimeZone else {
            print("Time zone is nil – cannot save chart.")
            return
        }

        let natalChart = ChartCake(birthDate: birthDate, latitude: latitude, longitude: longitude)
      

        // 2. Save to UserDefaults (update default)
        UserDefaultsManager.shared.saveChart(natalChart)

        // 3. Optional: Notify delegate if needed
        delegate?.didUpdateChart(birthDate: birthDate, latitude: latitude, longitude: longitude, name: name)

        // 4. Dismiss
        navigationController?.popViewController(animated: true)
    }

}
