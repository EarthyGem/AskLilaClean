import UIKit
import SwiftEphemeris
import CoreData
import AppTrackingTransparency
class SceneDelegate: UIResponder, UIWindowSceneDelegate, LoginDelegate, UserProfileDelegate {
    var window: UIWindow?
    var chartCake: ChartCake?
    
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        print("🔍 DEBUG: SceneDelegate initializing app")
        
        // Check if user is already logged in using UserDefaults
        if let _ = UserDefaults.standard.string(forKey: "currentUserId") {
            if let savedChartCake = UserDefaultsManager.shared.loadChart() {
                print("✅ DEBUG: Successfully loaded chart from UserDefaults")
                self.chartCake = savedChartCake
                showMainScreen(chartCake: savedChartCake)  // ✅ UPDATED
            } else {
                print("⚠️ DEBUG: No chart found in UserDefaults, checking CoreData")
                checkForExistingChart()
            }
        } else {
            // User is not logged in, show login screen
            showLoginScreen()
        }
        
        window?.makeKeyAndVisible()
    }
    
    
    private func checkForExistingChart() {
        if let cachedChart = UserDefaultsManager.shared.loadChart() {
            print("✅ DEBUG: Loaded chart from UserDefaults")
            self.chartCake = cachedChart
            showMainScreen(chartCake: cachedChart)  // ✅ UPDATED
            return
        }
        
        let fetchRequest: NSFetchRequest<ChartEntity> = ChartEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let results = try context.fetch(fetchRequest)
            
            if let chartEntity = results.first,
               let chart = convertCoreDataEntityToChartCake(chartEntity) {
                self.chartCake = chart
                cacheChartLocally(chart)
                showMainScreen(chartCake: chart)  // ✅ UPDATED
            } else {
                showBirthChartInputScreen()
            }
        } catch {
            print("❌ Error fetching user charts from CoreData: \(error.localizedDescription)")
            showBirthChartInputScreen()
        }
    }
    
    private func cacheChartLocally(_ chart: ChartCake) {
        print("🔍 DEBUG: Caching chart locally")
        UserDefaultsManager.shared.saveChart(chart)
        print("✅ DEBUG: Chart cached successfully")
    }
    
    private func convertCoreDataEntityToChartCake(_ entity: ChartEntity) -> ChartCake? {
        guard let name = entity.name,
              let birthDate = entity.birthDate,
              let birthPlace = entity.birthPlace,
              let strongestPlanet = entity.strongestPlanet,
              let mostHarmoniousPlanet = entity.mostHarmoniousPlanet,
              let mostDiscordantPlanet = entity.mostDiscordantPlanet,
              let timeZoneIdentifier = entity.timeZoneIdentifier,
              let category = entity.category,
              let sentenceText = entity.sentenceText else {
            return nil
        }
        
        return ChartCake(
            birthDate: birthDate,
            latitude: entity.latitude,
            longitude: entity.longitude,
            name: name
        )
    }
    
    private func saveChartToCoreData(chart: ChartCake) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let chartEntity = ChartEntity(context: context)

        chartEntity.name = chart.name
        chartEntity.birthDate = chart.natal.birthDate
        chartEntity.latitude = chart.natal.latitude
        chartEntity.longitude = chart.natal.longitude
        chartEntity.birthPlace = ""
        chartEntity.strongestPlanet = ""
        chartEntity.mostHarmoniousPlanet = ""
        chartEntity.mostDiscordantPlanet = ""
        chartEntity.timeZoneIdentifier = ""
        chartEntity.category = ""
        chartEntity.sentenceText = ""

        do {
            try context.save()
            print("✅ Chart saved to CoreData successfully")
        } catch {
            print("❌ Error saving chart to CoreData: \(error.localizedDescription)")
        }
    }

    
    private func showLoginScreen() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        window?.rootViewController = UINavigationController(rootViewController: loginVC)
    }
    
    private func showBirthChartInputScreen() {
        let userProfileVC = MyUserProfileViewController()
        userProfileVC.delegate = self
        print("🧩 SceneDelegate set as delegate for MyUserProfileViewController")
        window?.rootViewController = UINavigationController(rootViewController: userProfileVC)
    }
    
    
    private func showMainScreen(chartCake: ChartCake) {
        self.chartCake = chartCake
        print("🚀 DEBUG: showMainScreen() called with chartCake: \(chartCake.name ?? "Unnamed")")
        
        let agentChatVC = MyAgentChatController()
        agentChatVC.chartCake = chartCake
        
        // You can either push it (if you're in a nav controller) or make it the root
        let navController = UINavigationController(rootViewController: agentChatVC)
        window?.rootViewController = navController
    }
    
    func didFinishEnteringUserProfile(with chartCake: ChartCake) {
        print("🌟 DEBUG: SceneDelegate received chartCake: \(chartCake.name ?? "Unnamed")")
        UserDefaultsManager.shared.saveChart(chartCake)
        showMainScreen(chartCake: chartCake)
    }
    // MARK: - LoginDelegate
    func didLoginSuccessfully() {
        // After login, check if the user has a chart
        checkForExistingChart()
    }
    // Save chartCake to UserDefaults
    
    func requestTrackingPermissionIfNeeded() {
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("✅ ATT status: \(status.rawValue)")
                    UserDefaults.standard.set(status.rawValue, forKey: "attStatus")
                }
            } else {
                print("ℹ️ ATT already determined: \(status.rawValue)")
            }
        } else {
            print("ℹ️ ATT not supported on this iOS version")
        }
    }
    // Other SceneDelegate lifecycle methods
    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes to CoreData when app enters background
        saveContext()
    }
    
    // Save CoreData context
    func saveContext() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("❌ Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// Add these methods to your SceneDelegate
extension SceneDelegate: EditChartViewControllerDelegate {
    // This method is called when the chart is updated in the EditChartViewController
   
    func updateChartInCoreData(chart: ChartCake) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ChartEntity> = ChartEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            
            if let chartEntity = results.first {
                // Update existing chart
                chartEntity.name = chart.name
                chartEntity.birthDate = chart.natal.birthDate
                chartEntity.latitude = chart.natal.latitude
                chartEntity.longitude = chart.natal.longitude

                try context.save()
                print("✅ Chart updated in CoreData successfully")
            } else {
                // No chart found, create a new one
                saveChartToCoreData(chart: chart)
            }
        } catch {
            print("❌ Error updating chart in CoreData: \(error.localizedDescription)")
        }
    }

    
    func saveChartCakeToUserDefaults(chartCake: ChartCake) {
        // Create a dictionary representation of chartCake
        let chartData: [String: Any] = [
            "birthDate": chartCake.natal.birthDate.timeIntervalSince1970,
            "latitude": chartCake.natal.latitude,
            "longitude": chartCake.natal.longitude,
            "name": chartCake.name ?? ""
        ]
        
        // Save directly to UserDefaults
        UserDefaults.standard.set(chartData, forKey: "savedChartCake")
        print("Chart saved to UserDefaults successfully")
    }

    func loadChartCakeFromUserDefaults() -> ChartCake? {
        guard let chartData = UserDefaults.standard.dictionary(forKey: "savedChartCake"),
              let birthDateInterval = chartData["birthDate"] as? TimeInterval,
              let latitude = chartData["latitude"] as? Double,
              let longitude = chartData["longitude"] as? Double,
              let name = chartData["name"] as? String else {
            print("Failed to load chart from UserDefaults")
            return nil
        }
        
        let birthDate = Date(timeIntervalSince1970: birthDateInterval)
        let chartCake = ChartCake(
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude,
            name: name
        )
        
        print("Chart loaded from UserDefaults successfully")
        return chartCake
    }
    
    

    // Replace this method in SceneDelegate.swift
    func showEditChartScreen() {
        print("🔧 showEditChartScreen called in SceneDelegate")
        
        // Don't look for MyAgentChatController - instead use the current chartCake directly
        let editVC = EditChartViewController()
        editVC.chartCake = self.chartCake
        editVC.delegate = self
        
        // Get the current topmost view controller and present from there
        if let rootVC = window?.rootViewController {
            let topmostVC = getTopmostViewController(from: rootVC)
            print("🔍 Found topmost ViewController: \(type(of: topmostVC))")
            
            // Present modally instead of pushing
            let navController = UINavigationController(rootViewController: editVC)
            topmostVC.present(navController, animated: true) {
                print("✅ Edit chart screen presented successfully")
            }
        } else {
            print("❌ No root view controller found")
        }
    }

    // Add this helper method to SceneDelegate
    func getTopmostViewController(from viewController: UIViewController) -> UIViewController {
        // If it's a navigation controller, get the visible view controller
        if let navigationController = viewController as? UINavigationController {
            return getTopmostViewController(from: navigationController.visibleViewController ?? viewController)
        }
        
        // If it's a tab controller, get the selected view controller
        if let tabController = viewController as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return getTopmostViewController(from: selected)
            }
        }
        
        // If it's presenting something, get the presented view controller
        if let presented = viewController.presentedViewController {
            return getTopmostViewController(from: presented)
        }
        
        // Otherwise, return the view controller itself
        return viewController
    }
    func didUpdateChart(birthDate: Date, latitude: Double, longitude: Double, name: String) {
        // Recalculate the chart
        let timeZone = TimeZone.current // Or get from existing logic
        let natal = ChartCake(birthDate: birthDate, latitude: latitude, longitude: longitude, name: name)
       

        // Save to UserDefaults
        UserDefaultsManager.shared.saveChart(natal)

        // Inject updated chart back into MyAgentChatController
        if let nav = window?.rootViewController as? UINavigationController,
           let agentChat = nav.viewControllers.first(where: { $0 is MyAgentChatController }) as? MyAgentChatController {
            agentChat.chartCake = natal
            agentChat.transitChartCake = nil // reset
            agentChat.otherChart = nil
            agentChat.messages.removeAll()
            agentChat.viewDidLoad() // reload UI with new chart
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("🌱 Scene became active")

        // Set Claude (index 1) as the default AI service if not already set
        if UserDefaults.standard.object(forKey: "selectedAIService") == nil {
            UserDefaults.standard.set(1, forKey: "selectedAIService")
            print("✅ Set Claude as default AI service")
        }

        // Delay a little to avoid race conditions at app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.requestTrackingPermissionIfNeeded()
        }
    }

}
