//
//  DocTypeModel.swift
//  BIVN
//
//  Created by TVO_M1 on 30/11/2023.
//

import Foundation
class DocTypeModel: Codable {
    var message: String?
    var code: Int?
    var data: DataDocTypeModel?
    
    func isOutOfDate() -> Bool{
        if self.code == 64 {
            return true
        }
        return false
    }
    
    func isNotAssignInventory() -> Bool{
        if self.code == 65 {
            return true
        }
        return false
    }
    
    func isShowChooseDocType() -> ChooseDocType{
        let isDocTypeAE = self.data?.isDocTypeAE ?? false
        let isDocTypeB = self.data?.isDocTypeB ?? false
        let isDocTypeC = self.data?.isDocTypeC ?? false
        if isDocTypeAE && isDocTypeC && isDocTypeB {
            return .aebc
        } else if isDocTypeAE && isDocTypeC {
            return .aec
        } else if isDocTypeAE && isDocTypeB {
            return .aeb
        } else if isDocTypeC && isDocTypeB {
            return .bc
        } else if isDocTypeAE {
            return .ae
        } else if isDocTypeB {
            return .b
        } else {
            return .c
        }
    }
}
struct DataDocTypeModel : Codable {
    var isDocTypeAE : Bool?
    var isDocTypeB : Bool?
    var isDocTypeC : Bool?
}

enum ChooseDocType {
    case aebc
    case aeb
    case aec
    case bc
    case ae
    case b
    case c
}
