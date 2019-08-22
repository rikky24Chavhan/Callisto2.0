//
//  ImageViewerViewController.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 5/11/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

public final class ImageViewerViewController: UIViewController {

    // MARK: - Properties

    private let image: UIImage
    private let imageView: UIImageView

    // MARK: - Lifecycle

    public required init?(coder aDecoder: NSCoder) { fatalError("Use init(image:) instead") }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) { fatalError("Use init(image:) instead") }

    public init(image: UIImage) {
        self.image = image

        imageView = UIImageView(image: self.image)

        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    // MARK: - Actions

    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Setup

    private func setup() {
        setupBackground()
        setupImageView()
        setupDismissButton()
    }

    private func setupBackground() {
        let blurEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffectView)

        visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupImageView() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let imageViewHeight = image.size.height / (image.size.width / screenWidth)

        imageView.isUserInteractionEnabled = true
        imageView.frame = CGRect(
            x: 0,
            y: screenHeight/2 - imageViewHeight/2,
            width: screenWidth,
            height: imageViewHeight)
        view.addSubview(imageView)
    }

    private func setupDismissButton() {
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(#imageLiteral(resourceName: "xButton"), for: .normal)
        dismissButton.tintColor = .piDenim
        dismissButton.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)

        dismissButton.topAnchor.constraint(equalTo: safeTopAnchor, constant: 0).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
    }
}

extension UIViewController {
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return view.safeAreaLayoutGuide.topAnchor
        } else {
            return topLayoutGuide.bottomAnchor
        }
    }
}
