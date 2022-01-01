//
//  Card.swift
//  ZhongHao_4.1
//
//  Created by Hao Zhong on 8/11/21.
//

import Foundation

class Card: Equatable {
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.imageName == rhs.imageName && lhs.isFlipped == rhs.isFlipped
    }
    
    // Stored Properties
    var imageName = ""
    var isFlipped = false
    
}
