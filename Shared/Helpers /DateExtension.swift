//
//  DateExtension.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import Foundation

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}
