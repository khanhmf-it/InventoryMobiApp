//
//  Storyboards.swift
//  BIVN
//
//  Created by Tan Tran on 22/11/2023.
//

import UIKit

extension Storyboards {
    private var boardName: String {
        switch self {
        case .login, .main, .detailHistory:
            return "Main"
        case .inventoryUser:
            return "InventoryUser"
        }
    }
    
    /// Respective controller identifier
    private var identifier: String {
        switch self {
        case .login: return LoginViewController.identifier
        case .main: return MainViewController.identifier
        case .detailHistory: return DetailHistoryTicketVC.identifier
        case .inventoryUser: return ScanUserIDController.identifier
        }
    }
    
    func instantiate() -> UIViewController {
        let storyboard = UIStoryboard(name: boardName, bundle: Bundle.main)
        if #available(iOS 13.0, *) {
            let controller = storyboard.instantiateViewController(identifier: identifier)
            return controller
        } else {
            let controller = storyboard.instantiateViewController(withIdentifier: identifier)
            return controller
        }
    }
}

