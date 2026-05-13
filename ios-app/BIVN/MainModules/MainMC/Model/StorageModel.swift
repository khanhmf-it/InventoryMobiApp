//
//  StorageModel.swift
//  BIVN
//
//  Created by Tinhvan on 21/09/2023.
//

import Foundation

struct StorageModel: Codable {
    var message: String?
    var code: Int?
    var data: [DataStorageModel]?
    var typeOfBusiness: Int?
}

struct DataStorageModel: Codable {
    var id: String?
    var layout: String?
}
