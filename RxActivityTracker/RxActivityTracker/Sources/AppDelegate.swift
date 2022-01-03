//
//  AppDelegate.swift
//  RxActivityTracker
//
//  Created by 홍경표 on 2021/12/30.
//

import UIKit

import Then
import SnapKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        let mainVC = MainVC(reactor: .init(someService: SomeService()))
        let navi = UINavigationController(rootViewController: mainVC)
        window?.rootViewController = navi
        
        return true
    }
    
}

