//
//  Storyboards.swift
//  BIVN
//
//  Created by Luyện Đào on 22/11/2023.
//

import UIKit

extension Storyboards {
    private var boardName: String {
        switch self {
        case .login, .main, .qrInventory, .scanCodeMC,  .listMonitorSheet, .popupViewController:
            return "Main"
        case .filterInventory, .sheetsInventory, .acctionInventory, .historyInventoryDetail, .waitConfirmMonitor:
            return "AccessoryMonitor"
        case .inventoryUser:
            return "InventoryUser"
        case .AccepticketC:
            return "AccepticketC"
        case .ballotCount, .filterTicketC, .sheetPresentation, .waitConfirmationC, .detailHistoryTicketC, .chooseModelDoc, .scanTicketB, .accessoryNotInventory, .scanTicketC:
            return "TicketC"
        case .accessory, .detailTicketsC, .historyAccessory:
            return "Accessory"
        case .listError , .ticketDetailA, .errorCorrection:
            return "ListError"
            
        }
    }
    
    private var identifier: String {
        switch self {
        case .login: return LoginViewController.identifier
        case .main: return MainViewController.identifier
        case .listMonitorSheet: return ListMonitoringSheetsVC.identifier
        case .ballotCount: return BallotCountViewController.identifier
        case .filterTicketC: return FilterTicketViewController.identifier
        case .sheetPresentation: return SheetPresentationViewController.identifier
        case .filterInventory: return FilterMonitorSheetsViewController.identifier
        case .sheetsInventory: return SheetsInventoryViewController.identifier
        case .inventoryUser: return ScanUserIDController.identifier
        case .qrInventory: return QRInventoryVC.identifier
        case .waitConfirmationC: return WaitConfirmationViewController.identifier
        case .scanCodeMC: return ScanCodeMCViewController.identifier
        case.AccepticketC: return AccepticketCController.identifier
        case .detailHistoryTicketC: return HistoryDetailDocCViewController.identifier
        case .waitConfirmMonitor: return WaitConfirmMonitorViewController.identifier
        case .acctionInventory: return ActionInventoryViewController.identifier
        case .historyInventoryDetail: return HistoryInventoryDetailViewController.identifier
        case .popupViewController: return PopUpViewController.identifier
        case .chooseModelDoc: return ChooseModelDocViewController.identifier
        case .scanTicketB: return ScanCodeTicketBViewController.identifier
        case .scanTicketC: return ScanCodeTicketCViewController.identifier
        case .accessoryNotInventory: return ListAccessoryNotInventoryViewController.identifier
        case .accessory: return AccessoryController.identifier
        case .listError: return ListErrorController.identifier
        case .ticketDetailA: return TicketDetailAViewController.identifier
        case .detailTicketsC: return DetailTicketCController.identifier
        case .errorCorrection: return ErrorCorrectionViewController.identifier
        case .historyAccessory: return HistoryController.identifier
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

