//
//  AppDelegate.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 2/27/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

import Fabric
import Crashlytics
import DeviceCheck

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let apiClient = PilotAPIClient()

    let primaryUserStorage = PilotPrimaryUserStorage()

    let reachability = Reachability()

    let locationOffsetStorage = LocationOffsetKeychainStorage()

    lazy var loginClient: PilotLoginClient = PilotLoginClient(
        apiClient: self.apiClient,
        primaryUserStorage: self.primaryUserStorage,
        reachability: reachability
    )

    lazy var onboardingManager: OnboardingManager = PilotOnboardingManager(primaryUserStorage: self.primaryUserStorage)

    // TODO: Figure out a better way to handle this failure
    lazy var mealDataController: MealDataController = try! RealmMealDataController(apiClient: self.apiClient)
    lazy var offlineSyncController: OfflineMealSyncController = OfflineMealSyncController(dataController: self.mealDataController)

    lazy var locationController: LocationController = LocationController(
        apiClient: self.apiClient,
        loginUserProvider: self.loginClient,
        locationOffsetProvider: self.locationOffsetStorage
    )

    lazy var healthKitController: HealthKitController = HealthKitController(
        apiClient: self.apiClient,
        loginUserProvider: self.loginClient
    )

    lazy var navigator: AppNavigator = AppNavigator(
        window: self.window,
        apiClient: self.apiClient,
        loginClient: self.loginClient,
        userProvider: self.loginClient,
        onboardingManager: self.onboardingManager,
        mealDataController: self.mealDataController,
        healthKitController: self.healthKitController,
        locationController: self.locationController
    )

    override init() {
        super.init()

        setMondayAsFirstWeekday()
        apiClient.accessCredentialsProvider = loginClient
    }

    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
       
        GlobalAppearance.configure()

        window = UIWindow(frame: UIScreen.main.bounds)
        navigator.refreshRootViewController()
        window?.makeKeyAndVisible()

        locationController.startMonitoring()
        healthKitController.queryNewHourlyStepSamples()
        offlineSyncController.start()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        try? locationController.syncLocalObjects()
        try? healthKitController.syncLocalObjects()
        healthKitController.queryNewHourlyStepSamples()
        offlineSyncController.start()
        loginClient.refreshLogin(completion: { _ in return })
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    private func setMondayAsFirstWeekday() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let region = DateRegion(tz: TimeZone.current, cal: calendar, loc: Locale.current)
        Date.defaultRegion = region
    }
}
