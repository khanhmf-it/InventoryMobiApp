//
//  LoginModel.swift
//  BIVN
//
//  Created by Tinhvan on 19/09/2023.
//

import Foundation

struct LoginModel: Codable {
    var message: String?
    var code: Int?
    var data: DataLoginModel?
}

struct DataLoginModel: Codable {
    var userId: String?
    var username: String?
    var token: String?
    var refreshToken: String?
    var deviceId: String?
    var roleId: String?
    var roleName: String?
    var accountType: String?
    var expiredDate: String?
    var departmentId: String?
    var departmentName: String?
    var avatar: String?
    var userCode: String?
    var securiryStamp: String?
    var email: String?
    var phone: String?
    var fullName: String?
    var roleClaims: [RoleClaimsModel]?
    var mobileAccess: String?
    var inventoryLoggedInfo: InventoryLoggedInfo?
}

struct RoleClaimsModel: Codable {
    var roleId: String?
    var roleName: String?
    var claimType: String?
    var claimValue: String?
}

struct LogoutModel: Codable {
    var message: String?
    var code: Int?
    var data: DataLogoutModel?
}

struct DataLogoutModel: Codable {
    var success: String?
    var fail: String?
    var notExists: String?
}

struct InventoryLoggedInfo : Codable {
    var accountId: String?
    var userId: String?
    var userName: String?
    var inventoryRoleType: Int?
    var inventoryModel: InventoryModel?
}

struct InventoryModel: Codable {
    var inventoryId: String?
    var name: String?
    var inventoryDate: String?
    var status: Int?
    
}

struct RefreshTokenModel: Codable {
    var message: String?
    var code: Int?
    var data: TokenModel?
}

struct TokenModel: Codable {
    var userId: String?
    var token: String?
    var refreshToken: String?
    var expiredDate: String?
    var deviceId: String?
    
    func getCreateDate() -> Date{
       let dateConvert = expiredDate?.formatStringToDate(formatInput: TypeFormatDate.ServerFormat.rawValue) ?? Date()
        return dateConvert
    }
}
