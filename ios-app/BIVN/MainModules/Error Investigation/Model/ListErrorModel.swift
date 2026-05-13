//
//  ListErrorModel.swift
//  BIVN
//
//  Created by Bi on 7/1/25.
//

import Foundation
import Localize_Swift

class ListErrorModel: Codable {
    var code: Int?
    var data: [ResultErrorModel]?
}

class ResultErrorModel: Codable {
    var errorInvestigationId: String?
    var componentCode: String?
    var quantity: String?
    var errorMoneyAbs: String?
    var status: Int?
    var positionCode: String?
    var componentName: String?
}

