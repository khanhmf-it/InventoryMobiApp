//
//  StringExtension.swift
//  BIVN
//
//  Created by Tan Tran on 07/12/2023.
//

import UIKit

extension String {
    func formatDateWithInputAndOutputType(inputFormat: String, outputFormat: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = inputFormat
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.timeZone = TimeZone(identifier: "Vi")
        dateFormatterPrint.dateFormat = outputFormat
        if let date = dateFormatterGet.date(from: self) {
            let stringDate = dateFormatterPrint.string(from: date)
            return stringDate
        }
        return ""
    }
    
    func formatStringToDate(formatInput: String) -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = formatInput
        let dateResult = dateFormatterGet.date(from: self)
        return dateResult ?? Date()
    }
}

extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
