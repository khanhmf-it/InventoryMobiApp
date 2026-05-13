//
//  ViewDetailModel.swift
//  BIVN
//
//  Created by Bi on 14/1/25.
//

import Foundation

class ViewDetailModel: Codable {
    var code: Int?
    var data: ErrorInvestigationModel?
}

class ErrorInvestigationModel: Codable {
    var errorQuantity: String?
    var errorCategory: Int?
    var errorDetails: String?
    var confirmationImage1: String?
    var confirmationImageTitle1: String?
    var confirmationImage2: String?
    var confirmationImageTitle2: String?
}



