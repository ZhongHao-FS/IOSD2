//
//  ImageCollectionViewCell.swift
//  ZhongHao_4.1
//
//  Created by Hao Zhong on 8/12/21.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func flip() {
        imageView.isHidden = false
        UIView.transition(with: imageView, duration: 0.3, options: .transitionFlipFromLeft, animations: {self.imageView.alpha = 1}, completion: nil)
        
    }
    
    func flipBack(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
            
            UIView.transition(with: self.imageView, duration: 0.3, options: .transitionFlipFromRight, animations: {self.imageView.alpha = 0}, completion: {_ in self.imageView.isHidden = true})
                                        
            })
    }
    
    func remove() {
        UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut, animations: {
            self.imageView.alpha = 0
            self.backgroundColor = .clear
        }, completion: nil)

    }
}
