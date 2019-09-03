//
//  CarouselView+UICollectionViewDataSource.swift
//  CarouselView
//
//  Created by Rikky Chavhan on 20/08/19.
//  Copyright © 2019 L&T. All rights reserved.
//

import UIKit

extension CarouselView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsByDataSource * infinityItemsMultiplier
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let indexOfSelectedItem = visibleIndexOfSelectedItem()
        let pickerViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselViewConstants.carouselViewCellIdentifier, for: indexPath) as! CarouselCollectionViewCell
        let view = delegate?.carouselView(self, viewForItem: indexPath.item, index: indexForItem(indexPath.item), highlighted: indexPath.item == indexOfSelectedItem, reusingView: pickerViewCell.customView)
        pickerViewCell.backgroundColor = pickerCellBackgroundColor ?? UIColor.clear
        if let customView = view {
            pickerViewCell.customView = customView
        } else {
            let size = CGSize(span: itemSpan, lateralSpan: itemLateralSpan, direction: scrollingDirection)
            pickerViewCell.titleLabel.frame = CGRect(origin: .zero, size: size)
            pickerViewCell.contentView.addSubview(pickerViewCell.titleLabel)
            pickerViewCell.titleLabel.backgroundColor = UIColor.clear
            pickerViewCell.titleLabel.text = dataSource?.carouselView(self, titleForItem: indexPath.item, index: indexForItem(indexPath.item))

        }
        return pickerViewCell
    }
}
