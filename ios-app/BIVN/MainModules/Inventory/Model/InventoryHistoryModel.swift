//
//  InventoryHistoryModel.swift
//  BIVN
//
//  Created by Tinhvan on 28/11/2023.
//

import Foundation

struct InventoryHistoryModel: Codable {
    var message: String?
    var code: Int?
    var data: HistoryInvenModel?
}

struct HistoryInvenModel: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var docType: Int?
    var docName: String?
    var confirmBy: String?
    var updateAt: String?
    var createAt: String?
    var createdBy: String?
    var updatedBy: String?
    var status: Int?
    var comment: String?
    var evicenceImg: String?
    var note: String?
    var action: Int?
    var changeLogModel: ChangeLogModel?
    var historyDetailABEs: [HistoryDetailABEsModel]?
    var historyDetailCs: [HistoryDetailCsModel]?
//    var componentABEs: [componentABEs]?
//    var componentsCs: [ComponentsCs]?
}

struct ComponentsCs: Codable {
    var id: String?
    var inventoryId: String?
    var inventoryDocId: String?
    var componentCode: String?
    var modelCode: String?
    var isHighLight: Bool?
    var quantityOfBom: Int?
    var quantityPerBom: Int?
}

struct HistoryDetailABEsModel: Codable {
    var id: String?
    var inventoryId: String?
    var historyId: String?
    var quantityOfBom: Int?
    var quantityPerBom: Int?
}

struct HistoryDetailCsModel: Codable {
    var id: String?
    var inventoryId: String?
    var historyId: String?
    var componentCode: String?
    var modelCode: String?
    var quantityOfBom: Int?
    var quantityPerBom: Int?
    var isHighlight: Bool?
}

