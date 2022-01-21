//
//  DateExtension.swift
//  Deficit Revised
//
//  Created by Yotzin Castrejon on 4/27/21.
//

import Foundation

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}
