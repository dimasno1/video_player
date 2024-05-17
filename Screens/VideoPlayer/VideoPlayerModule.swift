//
//  VideoPlayerModule.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 10.05.24.
//

import UIKit
import AVFoundation

enum VideoPlayerModule {
    static func create(asset: AVAsset) -> UIViewController {
        let viewController = VideoPlayerViewController()
        let router = VideoPlayerRouter(root: viewController)

        let viewModel = VideoPlayerViewModel(
            asset: asset,
            router: router
        )
        viewController.viewModel = viewModel
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }
}
