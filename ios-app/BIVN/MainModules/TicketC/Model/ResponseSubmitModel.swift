//
//  ResponseSubmitModel.swift
//  BIVN
//
//  Created by Luyện Đào on 01/12/2023.
//

import Foundation

struct ResponseSubmitModel: Codable {
    var message: String?
    var code: Int?
    var data: DataResponseSubmit?
}

struct DataResponseSubmit: Codable {
    var status: Int?
    var inventoryId: String?
    var accountId: String?
    var docId: String?
}
