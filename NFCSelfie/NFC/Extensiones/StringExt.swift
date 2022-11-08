//
//  StringExt.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 24/10/22.
//

import Foundation

/// Some Utility methods for string -  access characters by index
extension String {
    subscript(_ i: Int) -> String {
        let idx1 = index(startIndex, offsetBy: i)
        let idx2 = index(idx1, offsetBy: 1)
        return String(self[idx1..<idx2])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        return String(self[start...])
    }
    
    func strip() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }
}
