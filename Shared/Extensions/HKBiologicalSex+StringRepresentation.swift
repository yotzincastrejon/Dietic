//
//  HKBiologicalSex+StringRepresentation.swift
//  Deficit
//
//  Created by Yotzin Castrejon on 4/25/21.
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
