//
//  DashboardTableViewCell.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import AlamofireImage

protocol DashboardTableViewCellDelegate: class {
    func dashboardTableViewCellDidReport(_ cell: DashboardTableViewCell)
}

final class DashboardTableViewCell: UITableViewCell {

    static var imageDownloader: ImageDownloader = {
        let imageDownloader = ImageDownloader()
        return imageDownloader
    }()

    // MARK: - Properties

    private struct Constants {
        static let defaultHeight: CGFloat = 160
        static let compactSeparatorHeight: CGFloat = 4
        static let extendedSeparatorHeight: CGFloat = 23
    }

    static let estimatedHeight: CGFloat = Constants.defaultHeight + Constants.extendedSeparatorHeight
    
    enum SeparatorType: Int {
        case none
        case compact
        case extended
    }

    var separatorType: SeparatorType = .compact {
        didSet {
            switch separatorType {
            case .none:
                separatorHeightConstraint.constant = 0
            case .compact:
                separatorHeightConstraint.constant = Constants.compactSeparatorHeight
            case .extended:
                separatorHeightConstraint.constant = Constants.extendedSeparatorHeight
            }

            heightConstraint.constant = Constants.defaultHeight + separatorHeightConstraint.constant
        }
    }

    var heightWithSeparator: CGFloat {
        return heightConstraint.constant
    }

    weak var delegate: DashboardTableViewCellDelegate?
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mealIndicatorView: UIView!
    @IBOutlet private weak var mealPreviewImageView: UIImageView!
    @IBOutlet private weak var mealNameLabel: UILabel!
    @IBOutlet private weak var mealLocationLabel: UILabel!
    @IBOutlet private weak var commonDetailContainerView: UIView!
    @IBOutlet private weak var portionIndicatorImageView: UIImageView!
    @IBOutlet private weak var portionLabel: UILabel!
    @IBOutlet private weak var progressContainerView: UIView!
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var noteIndicatorView: UIView!
    @IBOutlet private weak var reportButton: UIButton!
    @IBOutlet private weak var flagImageView: UIImageView!
    @IBOutlet private weak var mealReportedLabel: UILabel!
    @IBOutlet private weak var dosageRecommendationImageView: UIImageView!

    @IBOutlet private var noteIndicatorCommonMealLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var noteIndicatorTestMealLeadingConstraint: NSLayoutConstraint!

    private var heightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 160)
        heightConstraint.priority = 999.layoutPriority
        heightConstraint.isActive = true

        mealPreviewImageView.af_imageDownloader = DashboardTableViewCell.imageDownloader
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
        mealPreviewImageView.image = #imageLiteral(resourceName: "tile")
    }

    // MARK: - Actions

    func configure(with viewModel: DashboardTableViewCellViewModel) {
        // Indicator
        mealIndicatorView.backgroundColor = viewModel.tintColor

        // Labels
        mealNameLabel.text = viewModel.mealName
        mealLocationLabel.text = viewModel.mealLocation

        // Portion
        portionIndicatorImageView.image = viewModel.portionIndidatorImage
        portionLabel.text = viewModel.portionDescription

        // Circle Progress View
        circleProgressView.currentCount = viewModel.numberOfTimesMealLogged
        circleProgressView.maxCount = viewModel.mealLogGoal
        circleProgressView.outerRingColor = viewModel.circleProgressOuterCircleTrackColor
        circleProgressView.innerCircleColor = viewModel.circleProgressInnerCircleColor
        circleProgressView.outerRingProgressColor = viewModel.circleProgressRingColor

        // Note Indicator View
        noteIndicatorView.isHidden = viewModel.noteIndicatorHidden

        // Common/Test Meal Subviews
        if viewModel.isCommon {
            noteIndicatorTestMealLeadingConstraint.isActive = false
            noteIndicatorCommonMealLeadingConstraint.isActive = true
        } else {
            noteIndicatorCommonMealLeadingConstraint.isActive = false
            noteIndicatorTestMealLeadingConstraint.isActive = true
        }
        commonDetailContainerView.isHidden = !viewModel.isCommon
        mealLocationLabel.isHidden = viewModel.isCommon

        // Flag
        if viewModel.shouldAnimateReportCompletion {
            animateReportCompletion()
            viewModel.shouldAnimateReportCompletion = false
        } else {
            reportButton.isHidden = viewModel.reportButtonHidden
            flagImageView.isHidden = viewModel.flagIndicatorHidden
        }

        // Dosage Recommendation
        dosageRecommendationImageView.isHidden = viewModel.dosageRecommendationHidden
        updateDosageRecommendationImageViewMask(isHidden: viewModel.dosageRecommendationHidden)

        topContainerView.layoutIfNeeded()

        // Background
        backgroundColor = UIColor.piAlmostWhite

        // Background Image
        mealPreviewImageView.image = #imageLiteral(resourceName: "tile")
        if let imageURLRequest = viewModel.imageURLRequest {
            let scaledSize = mealPreviewImageView.bounds.size
            let imageFilter = DynamicImageFilter("Overlay", filter: { originalImage -> Image in
                let scaledImage = originalImage.af_imageAspectScaled(toFill: scaledSize)
                return scaledImage.withOverlay() ?? scaledImage
            })
            mealPreviewImageView.contentMode = .scaleAspectFill
            ImageDownloader.default.download(imageURLRequest) { [weak self] response in
                var downloadedImage: Image?
                switch response.result {
                    case .success(let image):
                        downloadedImage = image
                    case .failure(_):
                        break
                }
                guard let welf = self, let image = downloadedImage else {
                    return
                }
                let _ = imageFilter.filter(image)
                UIView.transition(with: welf.mealPreviewImageView,
                                  duration: 0.2,
                                  options: .transitionCrossDissolve,
                                  animations: { welf.mealPreviewImageView.image = image },
                                  completion: nil)
            }
        } else {
            mealPreviewImageView.contentMode = .scaleToFill
        }
    }

    private func animateReportCompletion() {
        // Animate state change between report button and flag icon
        reportButton.isHidden = false
        reportButton.alpha = 1

        flagImageView.isHidden = false
        flagImageView.alpha = 0
        flagImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)

        UIView.animate(
            withDuration: 0.3,
            delay: 0.4,
            options: UIView.AnimationOptions(),
            animations: {
                self.reportButton.alpha = 0
                self.reportButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0.05,
                    usingSpringWithDamping: 0.6,
                    initialSpringVelocity: 25,
                    options: UIView.AnimationOptions(),
                    animations: {
                        self.flagImageView.alpha = 0.6
                        self.flagImageView.transform = .identity
                    },
                    completion: { _ in
                        self.reportButton.isHidden = true
                        self.reportButton.alpha = 1
                        self.reportButton.transform = .identity
                    })
            })

        // Show "Meal Reported" text

        let initialLabelTransform = CGAffineTransform(translationX: 0, y: 20)
        mealReportedLabel.transform = initialLabelTransform

        UIView.animate(
            withDuration: 0.5,
            delay: 0.85,
            options: .curveEaseInOut,
            animations: {
                self.mealReportedLabel.alpha = 1
                self.mealReportedLabel.transform = .identity
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.5,
                    delay: 1.5,
                    options: UIView.AnimationOptions(),
                    animations: {
                        self.mealReportedLabel.alpha = 0
                        self.mealReportedLabel.transform = initialLabelTransform
                    },
                    completion: nil)
            })
    }

    private func updateDosageRecommendationImageViewMask(isHidden: Bool) {
        if isHidden {
            progressContainerView.layer.mask = nil
        } else {
            let maskFrame = topContainerView.convert(dosageRecommendationImageView.frame.insetBy(dx: 1, dy: 1), to: progressContainerView)
            let radius = maskFrame.width / 2
            let path = UIBezierPath(rect: progressContainerView.bounds)
            let circlePath = UIBezierPath(
                roundedRect: maskFrame,
                cornerRadius: radius)
            path.append(circlePath)
            path.usesEvenOddFillRule = true

            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            progressContainerView.layer.mask = maskLayer
        }
    }

    func cancelImageRequest() {
        mealPreviewImageView.af_cancelImageRequest()
    }

    @IBAction func reportButtonTapped(_ sender: UIButton) {
        delegate?.dashboardTableViewCellDidReport(self)
    }
}

fileprivate extension UIImage {
    func withOverlay() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)

        let rect = CGRect(origin: .zero, size: size)

        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!

        //// Color Declarations
        let color = UIColor(red: 0.039, green: 0.149, blue: 0.216, alpha: 0.400)
        let color2 = UIColor(red: 0.282, green: 0.325, blue: 0.345, alpha: 1.000)

        draw(in: CGRect(origin: .zero, size: size))

        //// Regular Drawing
        let regularPath = UIBezierPath(rect: rect)
        color.setFill()
        regularPath.fill()

        //// Lighten Drawing
        context.saveGState()
        context.setBlendMode(.lighten)

        let lightenPath = UIBezierPath(rect: rect)
        color2.setFill()
        lightenPath.fill()

        context.restoreGState()

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
