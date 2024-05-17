//
//  GalleryCellViewModel.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import RxSwift
import RxRelay
import Photos

final class GalleryCellViewModel {
    let asset: PHAsset

    private let manager: PHImageManager
    private let previewImageRelay = BehaviorRelay<UIImage?>(value: nil)

    private var requestID: PHImageRequestID?

    init(
        asset: PHAsset,
        manager: PHImageManager
    ) {
        self.manager = manager
        self.asset = asset
    }

    func willDisplay() {
        let targetSize = CGSize(
            width: UIScreen.main.bounds.width / 3,
            height: UIScreen.main.bounds.width / 3
        )
        let requestOptions = PHImageRequestOptions()

        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat

        requestID = manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.previewImageRelay.accept(image)
            }
        }
    }

    func didHide() {
        if let requestID {
            manager.cancelImageRequest(requestID)
        }
        previewImageRelay.accept(nil)
    }
}

extension GalleryCellViewModel: GalleryCellViewModelProtocol {
    var previewImage: Observable<UIImage?> {
        previewImageRelay.asObservable()
    }

    var durationString: Observable<String> {
        let string = Duration.seconds(asset.duration).formatted(
            Duration.TimeFormatStyle(pattern: .hourMinuteSecond)
        )
        return .just(string)
    }

    func prepareForReuse() {
        previewImageRelay.accept(nil)
    }
}

