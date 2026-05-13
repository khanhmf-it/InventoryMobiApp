//
//  PositionModel.swift
//  BIVN
//
//  Created by Tinhvan on 22/09/2023.
//

import Foundation

struct PositionModel: Codable {
    var message: String?
    var code: Int?
    var data: [DataPositionModel]?
}

struct DataPositionModel: Codable {
    var positionCode: String?
    var componentDetails: [ComponentDetailModel]?
}

struct ComponentDetailModel: Codable {
    var id: String?
    var componentName: String?
    var componentCode: String?
    var componentInfo: String?
    var supplierCode: String?
    var supplierName: String?
    var supplierShortName: String?
    var inventoryNumber: Double?
    var minInventoryNumber: Double?
    var maxInventoryNumber: Double?
    var note: String?
    var positionCode: String?
    var factoryId: String?
}

