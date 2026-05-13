//
//  DetailHistoryModel.swift
//  BIVN
//
//  Created by Tan Tran on 08/12/2023.
//

import Foundation
import Localize_Swift

struct DetailHistoryModel: Codable {
    var message: String?
    var code: Int?
    var data: ResultDataHistory?
}

struct ResultDataHistory: Codable {
    var docName: String?
    var status: Int?
    var action: Int?
    var createdAt: String?
    var confirmBy: String?
    var updateAt: String?
    var docType: Int?
    var id: String?
    var createdBy: String?
    var updatedBy: String?
    var inventoryDocId: String?
    var note: String?
    var inventoryId: String?
    var evicenceImg: String?
    var evicenceImgTitle: String?
    var comment: String?
    var changeLogModel: ChangeLogModels?
    var docOutputs: [DocComponentABEs]?
    var historyOutputs: [DocComponentABEs]?
    var historyDetailCs: [DocComponentCs]?
    var machineModel: String?
    var machineType: String?
    var stageNumber: String?
    var stageName: String?
    var modelCode: String?
    var lineName: String?
    var docCTotalPages: Int?
    
    func getStatus() -> String {
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
    
    func getPersonHistory() -> String {
        switch status {
        case 0, 1, 2, 3, 4:
            return "Người kiểm kê: ".localized()
        case 5:
            return "Người xác nhận: ".localized()
        default:
            return "Người giám sát: ".localized()
        }
    }
}
