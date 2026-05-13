//
//  DocCModel.swift
//  BIVN
//
//  Created by Luyện Đào on 27/11/2023.
//

import Foundation
import Localize_Swift

struct DocCModel: Codable {
    var message: String?
    var code: Int?
    var data: ArrayData?
}

struct ArrayData: Codable {
    var docCInfoModels: [DocCInfoModels]?
    var finishCount: Int?
    var totalCount: Int?
}

struct DocCInfoModels: Codable {
    var id: String?
    var inventoryId: String?
    var accountId: String?
    var status: Int?
    var docType: Int?
    var docCode: String?
    var modelCode: String?
    var machineModel: String?
    var machineType: String?
    var lineName: String?
    var lineType: String?
    var stageNumber: String?
    var stageName: String?
    var inventoryBy: String?
    var confirmedBy: String?
    
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
            return "Giám sát đạt".localized()
        case 7:
            return "Không đạt giám sát".localized()
        default:
            return ""
        }
    }
    
    func getColorStatus() -> String {
        switch status {
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
}
