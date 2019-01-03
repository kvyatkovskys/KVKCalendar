//
//  Array+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

extension Array {
    func split(half: Int) -> (left: [Element], right: [Element]) {
        let leftSplit = self[0..<half]
        let rightSplit = self[half..<self.count]
        return (Array(leftSplit), Array(rightSplit))
    }
}
