//
//  PartCodeModel.swift
//  BIVN
//
//  Created by Luyện Đào on 28/11/2023.
//

import Foundation
import Localize_Swift

class PartCodeModel: Codable {
    var message: String?
    var code: Int?
    var data: ResultData?
}

class ResultData: Codable {
    var docCode: String?
    var status: Int?
    var inventoryBy: String?
    var inventoryAt: String?
    var salesOrder: String?
    var note: String?
    var componentCode: String?
    var componentName: String?
    var positionCode: String?
    var docType: Int?
    var docComponentCs: [DocComponentCs]?
    var docComponentABEs: [DocComponentABEs]?
    var docHistories: [DocHistory]?
    var docCTotalPages: Int?
    var machineModel: String?
    var machineType: String?
    var stageNumber: String?
    var stageName: String?
    var modelCode: String?
    var lineName: String?
    
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
    
    func getStatusPartCode() -> String {
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

class DocComponentABEs: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var quantityOfBom: Double?
    var quantityPerBom: Double?
    var isCheckBox: Bool?
    var isCheck: Bool?
    
    init(id: String? = nil, inventoryId: String? = nil, inventoryDocId: String? = nil, quantityOfBom: Double? = nil, quantityPerBom: Double? = nil) {
        self.id = id
        self.inventoryId = inventoryId
        self.inventoryDocId = inventoryDocId
        self.quantityOfBom = quantityOfBom
        self.quantityPerBom = quantityPerBom
    }
}

class DocComponentCs: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var componentCode: String?
    var modelCode: String?
    var isHighLight: Bool?
    var quantityOfBom: Double?
    var quantityPerBom: Double?
    var isCheck: Bool?
    var isShowCheck: Bool?
    var isHighLightLocal: Bool?
    var isTickCheckBox: Bool?
}

class DocHistory: Codable {
    var id: String?
    var inventoryId: String?
    var comment: String?
    var action: Int?
    var evicenceImg: String?
    var inventoryDocId: String?
    var createdAt: String?
    var createdBy: String?
    var status: Int?
    var changeLogModel: ChangeLogModels?
    
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
    
    func getPerson() -> String {
        switch status {
        case 0, 1, 2, 3, 4:
            return "Người kiểm kê: ".localized()
        case 5:
            return "Người xác nhận: ".localized()
        default:
            return "Người giám sát: ".localized()
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
    
    func getCreateDate() -> Date{
       let dateConvert = createdAt?.formatStringToDate(formatInput: TypeFormatDate.ServerFormat.rawValue) ?? Date()
        return dateConvert
    }
}

class ChangeLogModels: Codable {
    var oldQuantity: Double?
    var newQuantity: Double?
    var oldStatus: Int?
    var newStatus: Int?
    var isChangeCDetail: Bool?
    
    func getTotalCount() -> String {
        if newQuantity == 0 || newQuantity == nil {
            return "Nhập tổng SL: ".localized()
        } else {
            return "Cập nhật tổng SL: ".localized()
        }
    }
    
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

struct ConvertDocComponentABEs: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var quantityOfBom: Double?
    var quantityPerBom: Double?
    var isCheckBox: Bool?
    var isCheck: Bool?
}

class ConvertDocComponentCs: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var componentCode: String?
    var modelCode: String?
    var isHighLight: Bool?
    var quantityOfBom: Double?
    var quantityPerBom: Double?
    var isCheck: Bool?
}
