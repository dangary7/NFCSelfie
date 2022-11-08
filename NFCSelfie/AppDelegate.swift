//
//  AppDelegate.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit

#if DEBUG
public func DLog(_ message:String,_ value: Any) {
    print("\(message) \(value)")
    
}
#else
public func DLog(_ message:String,_ value: Any) {
    NSLog("\(message) \(value)")
}
#endif

@available(iOS 13.0, *)
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var calledApp:String!
    var scheme:String!
    var fullUrl:String!
    var query:String!
    var nistFaceDict : Dictionary<String,Data>!
    var nistImgWidthDict : Dictionary<String,CGFloat>!
    var nistImgHeightDict : Dictionary<String,CGFloat>!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let defaults = UserDefaults.standard
        let defaultValue = ["FileCount" : 0]
        defaults.register(defaults: defaultValue)
        nistFaceDict = Dictionary.init()
        nistImgWidthDict = Dictionary.init()
        nistImgHeightDict = Dictionary.init()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication){
        if((self.window?.rootViewController?.presentedViewController) != nil){
            if(self.window?.rootViewController?.presentedViewController?.isKind(of: StartViewController.self))!{
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let viewControl : StartViewController = storyboard.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
                let navControl = UINavigationController.init(rootViewController: viewControl)
                window?.addSubview((navControl.view)!)
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    class func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "v\(version).\(build)"
    }

}

