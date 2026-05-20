

import Foundation

struct ErrorCategoryModel: Codable {
    var message: String?
    var code: Int?
    var data: [DataCategory]?
    var typeOfBusiness: Int?
}

struct DataCategory: Codable {
    var id: String?
    var errorCategoryKey: String?
    var errorCategoryName: String?
}

