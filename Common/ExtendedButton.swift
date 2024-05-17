//
//  ExtendedButton.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 14.05.24.
//

import UIKit

class ExtendedButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
}
