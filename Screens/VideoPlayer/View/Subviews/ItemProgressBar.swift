//
//  ItemProgressBar.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import AVFoundation

extension VideoPlayerViewController {
    final class ItemProgressBar: UIView {
        private let progressLayer = CAShapeLayer()
        private let synchronizedLayer: AVSynchronizedLayer
        private let duration: TimeInterval

        init(
            playerItem: AVPlayerItem,
            duration: TimeInterval
        ) {
            self.synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem)
            self.duration = duration
            super.init(frame: .zero)

            setup()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            progressLayer.frame = bounds
            synchronizedLayer.frame = bounds

            let path = CGMutablePath()
            path.move(to: .init(x: 0, y: bounds.midY))
            path.addLine(to: .init(x: bounds.maxX, y: bounds.midY))

            progressLayer.path = path
        }

        private func setup() {
            backgroundColor = UIColor.black.withAlphaComponent(0.16)
            progressLayer.strokeColor = UIColor.systemBlue.cgColor
            progressLayer.lineWidth = 4.0

            layer.addSublayer(synchronizedLayer)
            synchronizedLayer.addSublayer(progressLayer)

            progressLayer.add(
                .strokePath(
                    from: 0.0,
                    to: 1.0,
                    duration: duration
                ),
                forKey: nil
            )
        }
    }
}

private extension CAAnimation {
    static func strokePath(
        from start: Double,
        to progress: Double,
        duration: TimeInterval
    ) -> CABasicAnimation {
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = start
        strokeEndAnimation.toValue = progress
        strokeEndAnimation.duration = duration
        strokeEndAnimation.isRemovedOnCompletion = false
        strokeEndAnimation.beginTime = AVCoreAnimationBeginTimeAtZero

        return strokeEndAnimation
    }
}
