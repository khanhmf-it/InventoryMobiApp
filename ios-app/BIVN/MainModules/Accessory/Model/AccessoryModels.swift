//
//  demoModel.swift
//  BIVN
//
//  Created by TVO_M1 on 8/1/25.
//

import Foundation


class AccessoryModels: Codable {
    var message: String?
    var code: Int?
    var data: DataClass?
}


class DataClass: Codable {
    var componentCode, componentName: String?
    var status: Int?
    var errorQuantity: String?
    var position: String?
    var documentList: [DocumentList]?
    var errorMonyAbs: String?
    var plant: String?
    var wareHouseLocation: String?
}


class DocumentList: Codable {
    var docId: String?
    var accountQuantity: String?
    var docCode: String?
    var bom: String?
}
