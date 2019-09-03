//
//  CarouselView+UICollectionViewDelegate.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

extension CarouselView: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTappedItem(indexPath.item)
    }
}
