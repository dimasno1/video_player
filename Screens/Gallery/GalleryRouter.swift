//
//  GalleryRouter.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import AVFoundation

final class GalleryRouter {
    private unowned let root: UIViewController

    init(root: UIViewController) {
        self.root = root
    }

    func showVideo(asset: AVAsset) {
        let viewController = VideoPlayerModule.create(asset: asset)
        root.present(viewController, animated: true)
    }

    func showAlert(with message: String) {
        let viewController = UIAlertController(
            title: "Opps",
            message: message,
            preferredStyle: .alert
        )
        viewController.addAction(UIAlertAction(title: "OK", style: .default))
        root.present(viewController, animated: true)
    }
}
