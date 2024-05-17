//
//  VideoView.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import AVFoundation

extension VideoPlayerViewController {
    final class VideoView: UIView {
        var player: AVPlayer? {
            get {
                playerLayer.player
            } set {
                playerLayer.player = newValue
            }
        }

        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        private var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        override init(frame: CGRect) {
            super.init(frame: .zero)

            setup()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError()
        }

        private func setup() {
            playerLayer.contentsGravity = .resizeAspectFill
        }
    }
}
