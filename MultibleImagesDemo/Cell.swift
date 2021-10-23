//
//  Cell.swift
//  MultibleImagesDemo
//
//  Created by Sulfah on 23/10/2021.
//

import UIKit

class Cell: UICollectionViewCell {

    var imageCellDelegate: ImageCellDelegate!
    @IBOutlet weak var uiCloseBackground: UIVisualEffectView!
    @IBOutlet weak var uiClose: UIButton!
    @IBOutlet weak var image: UIImageView!
    
    var isEditing = false{
        didSet{
            uiCloseBackground.isHidden = !isEditing
        }
    }
    @IBAction func uiCloseTapped(_ sender: Any) {
        imageCellDelegate.deleteImage(withingCell: self)
    }
    
}
