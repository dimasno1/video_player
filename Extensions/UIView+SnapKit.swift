//
//  UIView+SnapKit.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 10.05.24.
//

import UIKit
import SnapKit

extension UIView {
    func fill(in superview: UIView) {
        layout(in: superview) { make in
            make.edges.equalToSuperview()
        }
    }

    func layout(in superview: UIView, constraintMaker: (ConstraintMaker) -> Void) {
        removeFromSuperview()
        superview.addSubview(self)

        self.snp.makeConstraints(constraintMaker)
    }
}
