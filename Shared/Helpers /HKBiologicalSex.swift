//
//  HKBiologicalSex.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import Foundation
import HealthKit

extension HKBiologicalSex {
  
  var stringRepresentation: String {
    switch self {
    case .notSet: return "Unknown"
    case .female: return "Female"
    case .male: return "Male"
    case .other: return "Other"
        @unknown default:
            fatalError()
    }
  }
}
