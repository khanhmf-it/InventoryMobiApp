//
//  DropdownModel.swift
//  BIVN
//
//  Created by Luyện Đào on 27/11/2023.
//

import Foundation

struct DropdownModel: Codable {
    var arrayOfStrings: [String]
    var code: Int

    enum CodingKeys: String, CodingKey {
        case arrayOfStrings = "data"
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var arrayOfStrings = try container.decode([String?].self, forKey: .arrayOfStrings)
        self.code = try container.decode(Int.self, forKey: .code)
        arrayOfStrings.removeAll { $0 == nil }
        self.arrayOfStrings = arrayOfStrings.compactMap { $0 }
    }
}

struct DropdownModelCode: Codable {
    var arrayOfStrings: [String]
    var code: Int

    enum CodingKeys: String, CodingKey {
        case arrayOfStrings = "data"
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var arrayOfStrings = try container.decode([String?].self, forKey: .arrayOfStrings)
        self.code = try container.decode(Int.self, forKey: .code)
        arrayOfStrings.removeAll { $0 == nil }
        self.arrayOfStrings = arrayOfStrings.compactMap { $0 }
    }
}

struct DropdownMachine: Codable {
    var message: String?
    var code: Int?
    var data: [DataResut]?
}

struct DataResut: Codable {
    var key: String?
    var displayName: String?
}
