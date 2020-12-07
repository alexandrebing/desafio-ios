//
//  MainCoordinator.swift
//  desafio-ios
//
//  Created by Alexandre Scheer Bing on 07/12/20.
//

import Foundation
import UIKit

class MainCoordinator {
    
    private let window: UIWindow
    private let navigationController: UINavigationController
    
    init (window: UIWindow, navigationController: UINavigationController = UINavigationController()) {
        self.window = window
        self.navigationController = navigationController
    }
    func start() {
        let viewController = StatementViewController.instantiate(with: StatementViewModel())
        viewController.coordinator = self
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        navigationController.pushViewController(viewController, animated: true)
    }
}