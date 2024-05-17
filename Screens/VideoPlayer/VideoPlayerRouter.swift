//
//  VideoPlayerRouter.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit

final class VideoPlayerRouter {
    private unowned let root: UIViewController

    init(root: UIViewController) {
        self.root = root
    }

    func close() {
        root.dismiss(animated: true)
    }
}
