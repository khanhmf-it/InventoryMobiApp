//
//  User.swift
//  BIVN
//
//  Created by Luyện Đào on 14/09/2023.
//

import Foundation

struct User: Codable {
    let id: Int
    let title: String

    enum CodingKeys: String, CodingKey {
        case id, title
    }
}

