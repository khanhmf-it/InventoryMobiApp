//
//  DetailTicketModel.swift
//  BIVN
//
//  Created by Tinhvan on 24/11/2023.
//

import Foundation
import Localize_Swift


struct DetailTicketModel: Codable {
    var message: String?
    var code: Int?
    var data: [DetailResponseDataTicket]?
}

struct DetailResponseDataTicket: Codable {
    var inventoryDoc: InventoryDoc?
    var components: [DocComponentABEs]?
    var histories: [ResultDataHistory]?
}

struct InventoryDoc: Codable {
    var id: String?
    var inventoryId: String?
    var status: Int?
    var docType: Int?
    var assignedAccountId: String?
    var componentCode: String?
    var componentName: String?
    var positionCode: String?
    var docCode: String?
    var modelCode: String?
    var machineModel: String?
    var machineType: String?
    var lineName: String?
    var lineType: String?
    var stageNumber: Int?
    var stageName: String?
    var saleOrderNo: String?
    var note: String?
    var inventoryBy: String?
    var confirmedBy: String?
    
    func getColorStatus() -> String {
        switch status {
        case 0:
            return R.color.textDarkBlue.name
        case 1:
            return R.color.textDefault.name
        case 2:
            return R.color.textGray.name
        case 3:
            return R.color.textYellow.name
        case 4:
            return R.color.textOrange.name
        case 5:
            return R.color.greenColor.name
        case 6:
            return R.color.textBlue.name
        case 7:
            return R.color.textRed.name
        default:
            return R.color.textDefault.name
        }
    }
    
    func getColorStatusPartCode() -> String {
        switch status {
        case 0:
            return "Chưa tiếp nhận".localized()
        case 1:
            return "Không kiểm kê".localized()
        case 2:
            return "Chưa kiểm kê".localized()
        case 3:
            return "Chờ xác nhận".localized()
        case 4:
            return "Cần chỉnh sửa".localized()
        case 5:
            return "Đã xác nhận".localized()
        case 6:
            return "Đã đạt giám sát".localized()
        case 7:
            return "Không đạt giám sát".localized()
        default:
            return ""
        }
    }
}

struct DocHistories: Codable {
    var id: String?
    var inventoryId: String?
    var comment: String?
    var action: Int?
    var evicenceImg: String?
    var inventoryDocId: String?
    var changeLogModel: ChangeLogModel?
}

struct ComponentModel: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var quantityOfBom: Int?
    var quantityPerBom: Int?
}

struct ChangeLogModel: Codable {
    var oldQuantity: Double?
    var newQuantity: Double?
    var oldStatus: Int?
    var newStatus: Int?
    var isChangeCDetail: Bool?
    
    func getNewStatus() -> String {
        switch newStatus {
        case 0:
            return "Chưa tiếp nhận".localized()
        case 1:
            return "Không kiểm kê".localized()
        case 2:
            return "Chưa kiểm kê".localized()
        case 3:
            return "Chờ xác nhận".localized()
        case 4:
            return "Cần chỉnh sửa".localized()
        case 5:
            return "Đã xác nhận".localized()
        case 6:
            return "Đã đạt giám sát".localized()
        case 7:
            return "Không đạt giám sát".localized()
        default:
            return ""
        }
    }
    
    func getColorNewStatus() -> String {
        switch newStatus {
        case 0:
            return R.color.textDarkBlue.name
        case 1:
            return R.color.textDefault.name
        case 2:
            return R.color.textGray.name
        case 3:
            return R.color.textYellow.name
        case 4:
            return R.color.textOrange.name
        case 5:
            return R.color.greenColor.name
        case 6:
            return R.color.textBlue.name
        case 7:
            return R.color.textRed.name
        default:
            return R.color.textDefault.name
        }
    }
    
    func getPersonHistoryChange() -> String {
        switch newStatus {
        case 0, 1, 2, 3, 4:
            return "Người kiểm kê: ".localized()
        case 5:
            return "Người xác nhận: ".localized()
        default:
            return "Người giám sát: ".localized()
        }
    }
}
