//
//  PhotoLibraryChangesObserver.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 14.05.24.
//

import Foundation
import Photos

final class PhotoLibraryChangesObserver: NSObject, PHPhotoLibraryChangeObserver {
    typealias ChangeAction = () -> Void

    var onChangeAction: ChangeAction?

    private var lastFetchResult: PHFetchResult<PHAsset>?

    func updateLastFetchResult(_ result: PHFetchResult<PHAsset>) {
        self.lastFetchResult = result
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard
            let lastFetchResult,
            let details = changeInstance.changeDetails(for: lastFetchResult)
        else {
            return
        }

        let countChanged = details.fetchResultBeforeChanges.count != details.fetchResultAfterChanges.count
        let hasInsertions = details.insertedIndexes?.isEmpty == false
        let hasChanges = details.changedIndexes?.isEmpty == false
        let hasRemoves = details.removedIndexes?.isEmpty == false
        let changesOccured = hasInsertions || hasChanges || hasRemoves || details.hasMoves || countChanged

        if changesOccured {
            onChangeAction?()
        }
    }
}
