//
//  CarouselView+UICollectionViewDelegateFlowLayout.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

extension CarouselView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lateralSpan = bounds.size.lateralSpan(forDirection: scrollingDirection)
        return CGSize(span: itemSpan, lateralSpan: lateralSpan, direction: scrollingDirection)
    }
}
