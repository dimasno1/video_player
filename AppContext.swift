//
//  AppContext.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 14.05.24.
//

import Foundation
import Photos

protocol ImageManagerProvider {
    var imageManager: PHImageManager { get }
}

protocol PhotoLibraryProvider {
    var photoLibrary: PHPhotoLibrary { get }
}

final class AppContext {
    let imageManager: PHImageManager
    let photoLibrary: PHPhotoLibrary

    init(
        imageManager: PHImageManager = PHCachingImageManager(),
        photoLibrary: PHPhotoLibrary = .shared()
    ) {
        self.imageManager = imageManager
        self.photoLibrary = photoLibrary
    }
}

extension AppContext: ImageManagerProvider {}
extension AppContext: PhotoLibraryProvider {}
