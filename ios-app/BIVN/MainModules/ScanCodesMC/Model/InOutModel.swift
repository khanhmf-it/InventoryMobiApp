//
//  InOutModel.swift
//  BIVN
//
//  Created by Tinhvan on 25/09/2023.
//

import Foundation

class InputStorageModel: Codable {
    var message: String?
    var code: Int?
    var data: String?
}

struct ComponentInOutModel: Codable {
    var positionCode: String
    var supplierCode: String
    var userId: String
    var quantity: Double
    var reason: String
    var typeOfBusiness: Int
    
    var dict: [String : Any] {
        return [
            "positionCode" : positionCode,
            "supplierCode" : supplierCode,
            "userId" : userId,
            "quantity" : quantity,
            "reason" : reason,
            "typeOfBusiness" : typeOfBusiness,
        ]
    }
}
