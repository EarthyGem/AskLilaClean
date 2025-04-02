import UIKit
import SwiftEphemeris
import FirebaseAuth

class CoTAnalysisViewController: UIViewController {

    weak var lilaViewController: MyAgentChatController?
    private let openAI = OpenAIService(apiKey: APIKeys.openAI)
    var partnerChartCake: ChartCake?
    private var isSynastryMode = false
    private var isProgressionMode = false
    private var isFourNetsMode = false

    private let outputTextView = UITextView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let analysisModeSegment = UISegmentedControl(items: ["Natal", "Progressions", "Synastry"])

    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }


    var chartCake: ChartCake!

    private var messageHistory: [[String: String]] = [
        ["role": "system", "content": "You are a wise, grounded astrologer who uses a logical, structured chain-of-thought method to analyze progressed aspects."]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // First, set up all UI elements and add them to the view hierarchy
        analysisModeSegment.selectedSegmentIndex = 0
        analysisModeSegment.translatesAutoresizingMaskIntoConstraints = false
        analysisModeSegment.addTarget(self, action: #selector(analysisModeChanged), for: .valueChanged)
        view.addSubview(analysisModeSegment)
        
        // Set up text view and add to hierarchy
        outputTextView.translatesAutoresizingMaskIntoConstraints = false
        outputTextView.font = UIFont.systemFont(ofSize: 16)
        outputTextView.isEditable = false
        outputTextView.isScrollEnabled = true
        view.addSubview(outputTextView)
        
        // Set up input field and add to hierarchy
        setupInputField()
        
        // Now that all views are added to the hierarchy, activate constraints
        NSLayoutConstraint.activate([
            analysisModeSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            analysisModeSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            outputTextView.topAnchor.constraint(equalTo: analysisModeSegment.bottomAnchor, constant: 10),
            outputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outputTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            outputTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
        ])
        
        startAnalysis()
    }

    private func logExchange(prompt: String, response: String) {
        let readingType: String = {
            if isSynastryMode {
                return "SYNASTRY"
            } else if isProgressionMode {
                return "PROGRESSIONS"
            } else {
                return "NATAL"
            }
        }()

        ConversationLogger.shared.logConversation(
            prompt: prompt,
            response: response,
            readingType: readingType,
            chartName: chartCake.name,
            partnerName: partnerChartCake?.name,
            transitDate: chartCake.transits.transitDate
        )
    }

   
    private func fetchAndInjectContextIfNeeded(completion: @escaping () -> Void) {
        guard let uid = currentUserID else {
            completion()
            return
        }

        ChartContextManager.shared.fetchChartSummary(for: uid) { [weak self] summary in
            guard let self = self, let summary = summary else {
                completion()
                return
            }

            let context = generateChartContextPrompt(from: summary)

            // Prevent duplicate context
            if !self.messageHistory.contains(where: { $0["role"] == "system" && $0["content"]?.contains("natal chart reveals") == true }) {
                self.messageHistory.insert(["role": "system", "content": context], at: 1)
            }

            completion()
        }
    }

   
    func buildUserChartProfile(from cake: ChartCake) -> UserChartProfile {
        let natal = cake.natal
        let aspectsScores = natal.allCelestialAspectScoresByAspect()

        let strongest = cake.strongestPlanet
        let strongestCoord = natal.planets.first { $0.body == strongest } ?? natal.sun
        let strongestHouse = natal.houseCusps.house(of: strongestCoord).number
        let ruledHouses = natal.houseCusps
            .influencedCoordinatesHouses(for: strongestCoord)
            .map { $0.number }
            .filter { $0 != strongestHouse }

        let sunHouse = natal.houseCusps.house(of: natal.sun).number
        let moonHouse = natal.houseCusps.house(of: natal.moon).number

        let ascSign = natal.ascendantCoordinate.sign
        let ascRulers = natal.houseCusps.customRulersForAllCusps()
            .filter { $0.key.number == 1 }
            .flatMap { $0.value }

        let ascRulerCoordinates: [Coordinate] = ascRulers.compactMap { ruler in
            natal.planets.first(where: { $0.body == ruler })
        }

        let ascRulerHouses: [Int] = ascRulerCoordinates.map { natal.houseCusps.house(of: $0).number }
        let ascRulerSigns: [Zodiac] = ascRulerCoordinates.map { $0.sign }

        let ascRulerAspects: [NatalAspectScore] = ascRulers.flatMap {
            topAspects(to: $0, in: aspectsScores)
        }
            let sunPower = cake.planetScores[natal.sun.body] ?? 0.0
            let moonPower = cake.planetScores[natal.moon.body] ?? 0.0
        let ascendantPower = cake.planetScores[natal.ascendantCoordinate.body] ?? 0.0
            let ascendantRulerPowers = ascRulers.map { cake.planetScores[$0] ?? 0.0 }

        

        return UserChartProfile(
            name: cake.name,
            birthDate: natal.birthDate,
            sex: cake.sex,

            strongestPlanet: strongest,
            strongestPlanetSign: cake.strongestPlanetSignSN,
            strongestPlanetHouse: strongestHouse,
            strongestPlanetRuledHouses: ruledHouses,

            sunSign: natal.sun.sign,
            sunHouse: sunHouse,
            sunPower: sunPower,
            moonSign: natal.moon.sign,
            moonHouse: moonHouse,
            moonPower: moonPower,
            ascendantSign: ascSign,
            ascendantPower: ascendantPower,
            ascendantRulerSigns: ascRulerSigns,
            ascendantRulers: ascRulers,
            ascendantRulerHouses: ascRulerHouses,
            ascendantRulerPowers: ascendantRulerPowers,

            dominantHouseScores: cake.houseScoresSN,
            dominantSignScores: cake.signScoresSN,
            dominantPlanetScores: cake.planetScoresSN,

            mostHarmoniousPlanet: cake.mostHarmoniousPlanetSN,
            mostDiscordantPlanet: cake.mostDiscordantPlanetSN,

            topAspectsToStrongestPlanet: topAspects(to: strongest, in: aspectsScores),
            topAspectsToMoon: topAspects(to: natal.moon.body, in: aspectsScores),
            topAspectsToAscendant: topAspects(to: natal.ascendantCoordinate.body, in: aspectsScores),
            topAspectsToAscendantRulers: ascRulerAspects
        )
    }
    func buildSynastryContext(chartA: ChartCake, chartB: ChartCake, synastryChart: SynastryChart) -> SynastryContext {

            let userA = SynastryUserProfile(
                name: chartA.name,
                birthDate: chartA.natal.birthDate,
                sex: chartA.sex,
                strongestPlanet: chartA.strongestPlanetSN,
                sunSign: chartA.natal.sun.sign,
                moonSign: chartA.natal.moon.sign,
                ascendantSign: chartA.natal.ascendantCoordinate.sign,
                dominantHouseScores: chartA.houseScoresSN,
                dominantSignScores: chartA.signScoresSN,
                dominantPlanetScores: chartA.planetScoresSN
            )

            let userB = SynastryUserProfile(
                name: chartB.name,
                birthDate: chartB.natal.birthDate,
                sex: chartB.sex,
                strongestPlanet: chartB.strongestPlanetSN,
                sunSign: chartB.natal.sun.sign,
                moonSign: chartB.natal.moon.sign,
                ascendantSign: chartB.natal.ascendantCoordinate.sign,
                dominantHouseScores: chartB.houseScoresSN,
                dominantSignScores: chartB.signScoresSN,
                dominantPlanetScores: chartB.planetScoresSN
            )

            let interaspects = SynastryBuilder.generateInteraspects(from: synastryChart)
            let compositeProfile = SynastryBuilder.generateCompositeProfile(from: synastryChart)

            let allActivationsA = SynastryBuilder.currentActivations(for: chartA)
            let allActivationsB = SynastryBuilder.currentActivations(for: chartB)

            let currentTransitsA = allActivationsA.filter { $0.fromLayer == .transit }
            let progressionsA = allActivationsA.filter { $0.fromLayer != .transit }

            let currentTransitsB = allActivationsB.filter { $0.fromLayer == .transit }
            let progressionsB = allActivationsB.filter { $0.fromLayer != .transit }

            return SynastryContext(
                userA: userA,
                userB: userB,
                interaspects: interaspects,
                compositeProfile: compositeProfile,
                currentTransitsA: currentTransitsA,
                currentTransitsB: currentTransitsB,
                progressionsA: progressionsA,
                progressionsB: progressionsB
            )
        }
    func topAspects(
        to planet: CelestialObject,
        in aspectsScores: [CelestialAspect: Double],
        limit: Int = 2
    ) -> [NatalAspectScore] {
        let sorted = chartCake.natal
            .filterAndFormatNatalAspects(by: planet, aspectsScores: aspectsScores)
            .sorted { $0.value > $1.value }  // Explicit sort for clarity

        return sorted.prefix(limit)
            .map { NatalAspectScore(aspect: $0.key, score: $0.value) }
    }

    
    func generateCurrentActivations(from cake: ChartCake) -> [Activation] {
        var allActivations: [Activation] = []

        let natalPlanets = cake.natal.planets.map { $0.body }

        for target in natalPlanets {
            // Extract aspects from each progression layer
            let majors = cake.progressedSimpleAspectsFiltered(by: target)
            let solarArcs = cake.solarArcSimpleAspectsFiltered(by: target)
            let minors = cake.minorProgressedSimpleAspectsFiltered(by: target)
            let transits = cake.transitSimpleAspectsFiltered(by: target)

            // Merge and map all into Activations
            let layerTuples: [(ProgressionLayer, [CelestialAspect])] = [
                (.major, majors),
                (.solarArc, solarArcs),
                (.minor, minors),
                (.transit, transits)
            ]

            for (layer, aspects) in layerTuples {
                let mapped = aspects.compactMap { aspect -> Activation? in
                  let kind = aspect.kind

                    return Activation(
                        source: aspect.body1.body,
                        target: aspect.body2.body,
                        aspect: kind,
                        orb: aspect.orb,
                        applying: aspect.type == .applying,
                        startDate: aspect.startDate,
                        endDate: aspect.endDate,
                        fromLayer: layer
                    )
                }

                allActivations.append(contentsOf: mapped)
            }
        }

        return allActivations
    }
    func setPartnerChart(_ partner: ChartCake) {
          self.partnerChartCake = partner
      }

      @objc private func analysisModeChanged(_ sender: UISegmentedControl) {
          isSynastryMode = sender.selectedSegmentIndex == 2
          isProgressionMode = sender.selectedSegmentIndex == 1

          if isProgressionMode {
              presentProgressionDatePicker()
          } else if isSynastryMode {
              presentPartnerChartSelection()
          } else {
              startAnalysis()
          }
      }

    private func presentProgressionDatePicker() {
        let datePickerVC = UIViewController()
        datePickerVC.preferredContentSize = CGSize(width: 320, height: 100)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePickerVC.view.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: datePickerVC.view.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: datePickerVC.view.centerYAnchor)
        ])

        let alert = UIAlertController(title: "Select Date for Progressions", message: nil, preferredStyle: .alert)

        alert.setValue(datePickerVC, forKey: "contentViewController")

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }

            self.chartCake = ChartCake(
                birthDate: self.chartCake.natal.birthDate,
                latitude: self.chartCake.natal.latitude,
                longitude: self.chartCake.natal.longitude,
                transitDate: datePicker.date
            )

            self.startAnalysis()
        }))

        self.present(alert, animated: true)
    }

      private func presentPartnerChartSelection() {
          let selectionVC = PartnerSelectionPopoverViewController()
          selectionVC.delegate = self
          let navController = UINavigationController(rootViewController: selectionVC)
          present(navController, animated: true)
      }

    private func startAnalysis() {
        fetchAndInjectContextIfNeeded { [weak self] in
            guard let self = self else { return }

            if self.isSynastryMode {
                self.runSynastryAnalysis()
            } else if self.isProgressionMode {
                self.runProgressionAnalysis()
            } else {
                self.runNatalAnalysis()
            }
        }
    }


      private func runNatalAnalysis() {
          let profile = buildUserChartProfile(from: chartCake)
          let prompt = NatalPromptGenerator.generatePrompt(from: profile)
          appendMessage(role: "user", content: prompt)

          openAI.sendConversation(messages: messageHistory) { [weak self] response in
              DispatchQueue.main.async {
                  if let response = response {
                      self?.appendMessage(role: "assistant", content: response)
                      self?.logExchange(prompt: prompt, response: response)
                  } else {
                      self?.appendMessage(role: "assistant", content: "No response or error.")
                  }
              }
          }

      }

      private func runProgressionAnalysis() {
          var prompt = "FOUR NETS\n\n"
          prompt += "Net One Events - Major Turning Points\n-------------------------------------\n"
          prompt += chartCake.netOne().joined(separator: "\n") + "\n\n"
          prompt += "Net Two Events - Important Developments\n---------------------------------------\n"
          prompt += chartCake.netTwo().joined(separator: "\n") + "\n\n"
          prompt += "Net Three Events - Minor Influences\n-----------------------------------\n"
          prompt += chartCake.netThree().joined(separator: "\n") + "\n\n"
          prompt += "Net Four Events - Triggers and Daily Events\n-------------------------------------------\n"
          prompt += chartCake.netFour().joined(separator: "\n")

          appendMessage(role: "user", content: prompt)

          openAI.sendConversation(messages: messageHistory) { [weak self] response in
              DispatchQueue.main.async {
                  if let response = response {
                      self?.appendMessage(role: "assistant", content: response)
                      self?.logExchange(prompt: prompt, response: response)
                  } else {
                      self?.appendMessage(role: "assistant", content: "No response or error.")
                  }
              }
          }
      }

      private func runSynastryAnalysis() {
          guard let partner = partnerChartCake else {
              outputTextView.text = "No partner chart found for synastry."
              return
          }
          let context = buildSynastryContext(chartA: chartCake, chartB: partner, synastryChart: SynastryChart(chart1: chartCake.natal, chart2: partner.natal, name1: chartCake.natal.name, name2: partner.natal.name))
        
          let prompt = SynastryPromptGenerator.generatePrompt(from: context)

          appendMessage(role: "user", content: prompt)

          openAI.sendConversation(messages: messageHistory) { [weak self] response in
              DispatchQueue.main.async {
                  if let response = response {
                      self?.appendMessage(role: "assistant", content: response)
                      self?.logExchange(prompt: prompt, response: response)
                  } else {
                      self?.appendMessage(role: "assistant", content: "No response or error.")
                  }
              }
          }
      }

      private func setupInputField() {
          inputField.translatesAutoresizingMaskIntoConstraints = false
          inputField.placeholder = "Ask Lila a question..."
          inputField.borderStyle = .roundedRect
          view.addSubview(inputField)

          sendButton.translatesAutoresizingMaskIntoConstraints = false
          sendButton.setTitle("Send", for: .normal)
          sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
          view.addSubview(sendButton)

          NSLayoutConstraint.activate([
              inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
              inputField.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
              inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
              inputField.heightAnchor.constraint(equalToConstant: 40),

              sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
              sendButton.bottomAnchor.constraint(equalTo: inputField.bottomAnchor),
              sendButton.heightAnchor.constraint(equalTo: inputField.heightAnchor),
              sendButton.widthAnchor.constraint(equalToConstant: 60)
          ])
      }

    @objc private func sendTapped() {
        guard let text = inputField.text, !text.isEmpty else { return }
        inputField.text = ""
        
        appendMessage(role: "user", content: text)

        openAI.sendConversation(messages: messageHistory) { [weak self] response in
            DispatchQueue.main.async {
                if let response = response {
                    self?.appendMessage(role: "assistant", content: response)
                    self?.logExchange(prompt: text, response: response)
                } else {
                    self?.appendMessage(role: "assistant", content: "Sorry, I didn’t understand that.")
                }
            }
        }
    }


      private func appendMessage(role: String, content: String) {
          messageHistory.append(["role": role, "content": content])
          outputTextView.text += "\n\n\(role.capitalized): \(content)"
      }
  }

  extension CoTAnalysisViewController: PartnerSelectionDelegate {
      func didSelectPartner(chartCake: ChartCake) {
          self.partnerChartCake = chartCake
          startAnalysis()
      }
  }



