//
//  HistoryAccessoryModels.swift
//  BIVN
//
//  Created by TVO_M1 on 15/1/25.
//
import Foundation

struct HistoryAccessoryModels: Codable {
    let message: String?
    let code: Int?
    let data: [HistoryData]?
}

struct HistoryData: Codable {
    let index, errorCategory: Int?
    let oldValue, newValue: String?
    let errorDetail, investigator, investigationTime, confirmInvestigationTime: String?
    let confirmationImage1, confirmationImageTitle1, confirmationImage2, confirmationImageTitle2: String?
    let errorCategoryName: String?
}
