//
//  GalleryViewModel.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import RxSwift
import RxRelay
import Photos

final class VideoAssetsGalleryViewModel {
    private let router: GalleryRouter
    private let manager: PHImageManager
    private let photoLibrary: PHPhotoLibrary
    private let changesObserver: PhotoLibraryChangesObserver

    private let previewModelsRelay = BehaviorRelay<[GalleryCellViewModel]>(value: [])
    private let activityVisibleRelay = BehaviorRelay(value: false)

    init(
        manager: PHImageManager,
        router: GalleryRouter,
        photoLibrary: PHPhotoLibrary,
        changesObserver: PhotoLibraryChangesObserver
    ) {
        self.manager = manager
        self.router = router
        self.photoLibrary = photoLibrary
        self.changesObserver = changesObserver
    }

    private func fetchVideoAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        changesObserver.updateLastFetchResult(fetchResult)

        activityVisibleRelay.accept(true)
        DispatchQueue.global(qos: .userInitiated).async {
            var viewModels: [GalleryCellViewModel] = []

            fetchResult.enumerateObjects { [weak self] asset, _, _ in
                guard let self else {
                    return
                }
                let viewModel = GalleryCellViewModel(
                    asset: asset,
                    manager: self.manager
                )
                viewModels.append(viewModel)
            }
            DispatchQueue.main.async { [weak self] in
                self?.activityVisibleRelay.accept(false)
                self?.previewModelsRelay.accept(viewModels)
            }
        }
    }
}

extension VideoAssetsGalleryViewModel: GalleryViewModelProtocol {
    var previews: Observable<[GalleryCellViewModelProtocol]> {
        previewModelsRelay.map { $0 }
    }

    var showActivity: Observable<Bool> {
        activityVisibleRelay.asObservable()
    }

    func viewDidLoad() {
        changesObserver.onChangeAction = { [weak self] in
            DispatchQueue.main.async {
                self?.fetchVideoAssets()
            }
        }
        photoLibrary.register(changesObserver)
        fetchVideoAssets()
    }

    func willDisplayCell(at indexPath: IndexPath) {
        previewModelsRelay.value[indexPath.row].willDisplay()
    }

    func didEndDisplayingCell(at indexPath: IndexPath) {
        previewModelsRelay.value[indexPath.row].didHide()
    }

    func didSelectCell(at indexPath: IndexPath) {
        let asset = previewModelsRelay.value[indexPath.row].asset

        guard asset.mediaType == .video else {
            router.showAlert(with: "Unsupported asset format")
            return
        }

        manager.requestAVAsset(forVideo: asset, options: nil) { [weak self] avAsset, error, _ in
            DispatchQueue.main.async {
                if let avAsset {
                    self?.router.showVideo(asset: avAsset)
                } else {
                    self?.router.showAlert(with: "Unable to show video")
                }
            }
        }
    }
}
