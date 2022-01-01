//
//  Deck.swift
//  ZhongHao_4.1
//
//  Created by Hao Zhong on 8/11/21.
//

import Foundation

class Deck {
    // Stored Properties
    var numOfCards: Int
    var cards: [Card]
    
    // Initializer
    init(_ number: Int) {
        self.numOfCards = number
        self.cards = [Card]()
        
        while cards.count < number {
            let imageIndex = Int.random(in: 0...149)
            let cardDrawn = Card()
            cardDrawn.imageName = "Image\(imageIndex)"
            let cardCopy = Card()
            cardCopy.imageName = "Image\(imageIndex)"
            // Add it to the deck if it is not in there already
            if !cards.contains(cardDrawn) {
                // 2 copies of the same card should be added to the deck
                self.cards.append(cardDrawn)
                self.cards.append(cardCopy)
            }
        }
        
        // Shuffle the deck so that it is challenging to play
        self.cards.shuffle()
    }
}
