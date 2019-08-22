//
//  MealEventDetailsHeaderView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import SwiftDate

protocol MealEventDetailsHeaderViewDelegate: class {
    func mealEventDetailsHeaderViewDateSelected(_ view: MealEventDetailsHeaderView)
    func mealEventDetailsHeaderViewPhotoSelected(_ view: MealEventDetailsHeaderView)
    func mealEventDetailsHeaderViewPhotoOptionsSelected(_ view: MealEventDetailsHeaderView)
}

public final class MealEventDetailsHeaderView: UITableViewHeaderFooterView {

    private struct Constants {
        static let addPhotoButtonContentSpacing: CGFloat = 16.0
    }

    // MARK: - Properties

    class var estimatedHeight: CGFloat {
        return 278
    }

    weak var delegate: MealEventDetailsHeaderViewDelegate?

    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var dateContainer: UIView!
    @IBOutlet private weak var dateEditIcon: UIImageView!
    @IBOutlet private weak var addPhotoButton: UIButton!
    @IBOutlet private weak var addPhotoButtonShadowView: UIView!
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var photoOptionsButton: UIButton!

    @IBOutlet var addPhotoButtonBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var photoImageViewBottomSpaceConstraint: NSLayoutConstraint!

    public override func awakeFromNib() {
        super.awakeFromNib()
        setupDateLabelTapGesture()
        setupAddPhotoButton()
        setupPhotoImageViewTapGesture()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }

    // MARK: - Setup

    private func setupDateLabelTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mealDateLabelTapped(sender:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        dateContainer.addGestureRecognizer(tapGesture)
    }

    private func setupAddPhotoButton() {
        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.setImage(#imageLiteral(resourceName: "addPhotoIcon"), for: .normal)
        addPhotoButton.setTitleColor(UIColor.piBlueyGrey, for: .normal)

        addPhotoButton.setTitle("No Photo", for: .disabled)
        addPhotoButton.setImage(#imageLiteral(resourceName: "PhotoIconDefault"), for: .disabled)
        addPhotoButton.setTitleColor(UIColor.piGreyblue.withAlphaComponent(0.3), for: .disabled)

        addPhotoButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Constants.addPhotoButtonContentSpacing)
        addPhotoButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: Constants.addPhotoButtonContentSpacing, bottom: 0, right: 0)

        let layer = addPhotoButton.layer
        layer.borderColor = UIColor.piPaleGreyThree.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 12.0
        layer.masksToBounds = true

        let shadowLayer = addPhotoButtonShadowView.layer
        shadowLayer.shadowColor = UIColor.piDenim.cgColor
        shadowLayer.shadowOffset = CGSize(width: 0, height: 3)
        shadowLayer.shadowRadius = 3.0
    }

    private func setupPhotoImageViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoButtonTapped(_:)))
        photoImageView.addGestureRecognizer(tapGesture)
    }

    // MARK: - View Model Configuration

    func configure(with viewModel: MealEventDetailsViewModel) {
        dateLabel.attributedText = viewModel.formattedDate.value
        dateEditIcon.isHidden = !viewModel.canEditMeal
        dateContainer.isUserInteractionEnabled = viewModel.isDateContainerUserInteractionEnabled

        photoImageView.image = viewModel.image.value
        photoImageView.isUserInteractionEnabled = viewModel.isPhotoImageViewUserInteractionEnabled
        photoOptionsButton.isHidden = viewModel.isPhotoOptionsButtonHidden
        addPhotoButton.isEnabled = viewModel.isAddPhotoButtonEnabled
        addPhotoButton.backgroundColor = viewModel.addPhotoButtonBackgroundColor
        addPhotoButton.titleLabel?.font = viewModel.addPhotoButtonTitleFont
        addPhotoButtonShadowView.layer.shadowOpacity = viewModel.addPhotoButtonShadowOpacity

        if viewModel.hasImage {
            addPhotoButtonBottomSpaceConstraint.isActive = false
            photoImageViewBottomSpaceConstraint.isActive = true
        } else {
            photoImageViewBottomSpaceConstraint.isActive = false
            addPhotoButtonBottomSpaceConstraint.isActive = true
        }
    }

    // MARK: - Actions

    @objc private func mealDateLabelTapped(sender: UITapGestureRecognizer) {
        delegate?.mealEventDetailsHeaderViewDateSelected(self)
    }

    @IBAction func photoButtonTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }

        if let _ = imageView.image {
            delegate?.mealEventDetailsHeaderViewPhotoSelected(self)
        } else {
            delegate?.mealEventDetailsHeaderViewPhotoOptionsSelected(self)
        }
    }

    @IBAction func photoOptionsButtonTapped(_ sender: UIButton) {
        delegate?.mealEventDetailsHeaderViewPhotoOptionsSelected(self)
    }
}
