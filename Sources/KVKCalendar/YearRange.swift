//
//  YearRange.swift
//  KVKCalendar
//
//  Created by Rakuyo on 9.9.2024.
//

import Foundation

public protocol YearRange {
    associatedtype Bound: Comparable

    /// The range's lower bound.
    var lowerBound: Bound { get }

    /// The range's upper bound.
    var upperBound: Bound { get }
}

extension Range: YearRange { }

extension ClosedRange: YearRange { }
