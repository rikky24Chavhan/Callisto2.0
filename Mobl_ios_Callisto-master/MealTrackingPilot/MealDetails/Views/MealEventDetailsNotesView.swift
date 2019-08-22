//
//  MealEventDetailsNotesView.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol MealEventDetailsNotesViewDelegate: class {
    func mealEventDetailsNotesViewDidSelectAddNote(_ view: MealEventDetailsNotesView)
}

public final class MealEventDetailsNotesView: UITableViewCell {

    private struct Constants {
        static let addNoteButtonContentSpacing: CGFloat = 16.0
        static let noteLabelEditableTopSpace: CGFloat = 20.0
    }

    // MARK: - Properties

    @IBOutlet private weak var addNoteContainerView: UIView!
    @IBOutlet private weak var addNoteButtonShadowView: UIView!
    @IBOutlet private weak var addNoteButton: UIButton!
    @IBOutlet private weak var addNoteSuggestionLabel: UILabel!
    @IBOutlet private weak var addNoteEmphasisLabel: UILabel!

    @IBOutlet private weak var notesContainerView: UIView!
    @IBOutlet private weak var noteLabel: UILabel!

    @IBOutlet private var addNoteButtonNoLabelTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private var addNoteContainerViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private var notesContainerViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var noteLabelTopConstraint: NSLayoutConstraint!

    weak var delegate: MealEventDetailsNotesViewDelegate?
    
    // MARK: - Lifecycle

    class var estimatedHeight: CGFloat {
        return 266
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        setupAddNoteButton()
        setupNotesContainerViewTapGesture()
    }

    private func setupAddNoteButton() {
        addNoteButton.setTitle("Add Note", for: .normal)
        addNoteButton.setImage(#imageLiteral(resourceName: "addNoteIcon"), for: .normal)
        addNoteButton.setTitleColor(UIColor.piBlueyGrey, for: .normal)

        addNoteButton.setTitle("No Notes", for: .disabled)
        addNoteButton.setImage(#imageLiteral(resourceName: "noNoteAdded"), for: .disabled)
        addNoteButton.setTitleColor(UIColor.piGreyblue.withAlphaComponent(0.3), for: .disabled)

        addNoteButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Constants.addNoteButtonContentSpacing)
        addNoteButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: Constants.addNoteButtonContentSpacing, bottom: 0, right: 0)

        let layer = addNoteButton.layer
        layer.cornerRadius = 12.0
        layer.masksToBounds = true

        let shadowLayer = addNoteButtonShadowView.layer
        shadowLayer.shadowColor = UIColor.piDenim.cgColor
        shadowLayer.shadowOffset = CGSize(width: 0, height: 3)
        shadowLayer.shadowRadius = 3.0
    }

    private func setupNotesContainerViewTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(composeNoteViewTapped))
        notesContainerView.addGestureRecognizer(tapGestureRecognizer)
    }

    func configure(with viewModel: MealEventDetailsViewModel, animated: Bool = false) {
        noteLabel.text = viewModel.notesViewText

        addNoteButton.isEnabled = viewModel.isAddNoteButtonEnabled
        addNoteButton.backgroundColor = viewModel.addNoteButtonBackgroundColor
        addNoteButton.titleLabel?.font = viewModel.addNoteButtonTitleFont

        addNoteContainerView.isHidden = viewModel.isAddNoteContainerViewHidden
        notesContainerView.isHidden = viewModel.isNotesContainerViewHidden
        notesContainerView.backgroundColor = viewModel.notesContainerViewBackgroundColor
        notesContainerView.isUserInteractionEnabled = viewModel.isNotesContainerViewUserInteractionEnabled
        noteLabelTopConstraint.constant = viewModel.canEditMeal ? Constants.noteLabelEditableTopSpace : 0

        addNoteButtonNoLabelTopSpaceConstraint.isActive = viewModel.isNoteSuggestionViewHidden
        addNoteSuggestionLabel.isHidden = viewModel.isNoteSuggestionViewHidden

        if animated {
            let duration: TimeInterval = 0.2

            let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
            borderColorAnimation.duration = duration
            borderColorAnimation.fromValue = addNoteButton.layer.borderColor
            borderColorAnimation.toValue = viewModel.addNoteButtonBorderColor.cgColor
            addNoteButton.layer.add(borderColorAnimation, forKey: "borderColor")

            let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
            borderWidthAnimation.duration = duration
            borderWidthAnimation.fromValue = addNoteButton.layer.borderWidth
            borderWidthAnimation.toValue = viewModel.addNoteButtonBorderWidth
            addNoteButton.layer.add(borderWidthAnimation, forKey: "borderWidth")

            let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowAnimation.duration = duration
            shadowAnimation.fromValue = addNoteButton.layer.shadowOpacity
            shadowAnimation.toValue = viewModel.addNoteButtonShadowOpacity
            addNoteButtonShadowView.layer.add(shadowAnimation, forKey: "shadowOpacity")

            UIView.animate(withDuration: duration) {
                self.addNoteEmphasisLabel.alpha = viewModel.isAddNoteButtonEmphasized ? 1 : 0
            }
        } else {
            addNoteEmphasisLabel.alpha = viewModel.isAddNoteButtonEmphasized ? 1 : 0
        }

        addNoteButton.layer.borderColor = viewModel.addNoteButtonBorderColor.cgColor
        addNoteButton.layer.borderWidth = viewModel.addNoteButtonBorderWidth
        addNoteButtonShadowView.layer.shadowOpacity = viewModel.addNoteButtonShadowOpacity

        if viewModel.hasNote {
            addNoteContainerViewBottomSpaceConstraint.isActive = false
            notesContainerViewBottomSpaceConstraint.isActive = true
        } else {
            notesContainerViewBottomSpaceConstraint.isActive = false
            addNoteContainerViewBottomSpaceConstraint.isActive = true
        }
    }

    @IBAction func composeNoteViewTapped(_ sender: Any) {
        delegate?.mealEventDetailsNotesViewDidSelectAddNote(self)
    }
}
