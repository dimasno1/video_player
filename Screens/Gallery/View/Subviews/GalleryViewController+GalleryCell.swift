//
//  GalleryViewController+GalleryCell.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import RxSwift

protocol GalleryCellViewModelProtocol {
    var previewImage: Observable<UIImage?> { get }
    var durationString: Observable<String> { get }

    func prepareForReuse()
}

extension GalleryViewController {
    final class GalleryCell: UICollectionViewCell {
        static var reuseIdentifier: String {
            String(describing: self)
        }

        var viewModel: GalleryCellViewModelProtocol! {
            didSet {
                bindViewModel()
            }
        }

        private let imageView = UIImageView()
        private let durationLabel = UILabel()

        private var disposeBag = DisposeBag()

        override init(frame: CGRect) {
            super.init(frame: frame)

            setup()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError()
        }

        override func prepareForReuse() {
            super.prepareForReuse()

            viewModel.prepareForReuse()
        }

        private func setup() {
            imageView.fill(in: contentView)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            durationLabel.textColor = .white
            durationLabel.font = .systemFont(ofSize: 13)
            durationLabel.layout(in: contentView) { make in
                make.trailing.bottom.equalToSuperview().inset(8.0)
            }
        }

        private func bindViewModel() {
            disposeBag = .init()

            viewModel.previewImage
                .bind(to: imageView.rx.image)
                .disposed(by: disposeBag)

            viewModel.durationString
                .bind(to: durationLabel.rx.text)
                .disposed(by: disposeBag)
        }
    }
}

