//
//  GalleryModule.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import Photos

enum GalleryModule {
    typealias Context = ImageManagerProvider & PhotoLibraryProvider

    static func create(context: Context) -> UIViewController {
        let viewController = GalleryViewController()
        let router = GalleryRouter(root: viewController)

        let viewModel = VideoAssetsGalleryViewModel(
            manager: context.imageManager,
            router: router,
            photoLibrary: context.photoLibrary,
            changesObserver: .init()
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
