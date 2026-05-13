//
//  HightLightTicketC.swift
//  BIVN
//
//  Created by TVO_M1 on 02/01/2024.
//

import Foundation
struct HightLightTicketC: Codable {
    var message: String?
    var data : DataHightLight?
    
}
struct DataHightLight: Codable{
    var docTypeCIsHightLights: Bool?
}
