//
//  GalleryViewController.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 13.05.24.
//

import UIKit
import RxSwift

protocol GalleryViewModelProtocol {
    var previews: Observable<[GalleryCellViewModelProtocol]> { get }
    var showActivity: Observable<Bool> { get }

    func viewDidLoad()

    func didEndDisplayingCell(at indexPath: IndexPath)
    func willDisplayCell(at indexPath: IndexPath)
    func didSelectCell(at indexPath: IndexPath)
}

final class GalleryViewController: UIViewController {
    var viewModel: GalleryViewModelProtocol!

    private let disposeBag = DisposeBag()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let collectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: .galleryGrid
        )
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupSubviews()
        bindViewModel()
        viewModel.viewDidLoad()
    }
}

private extension GalleryViewController {
    func setupSubviews() {
        collectionView.register(
            GalleryCell.self,
            forCellWithReuseIdentifier: GalleryCell.reuseIdentifier
        )
        collectionView.fill(in: view)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.layout(in: view) { make in
            make.center.equalToSuperview()
        }
    }

    func bindViewModel() {
        viewModel.previews.bind(to: collectionView.rx.items) { collectionView, index, cellModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GalleryCell.reuseIdentifier,
                for: .init(item: index, section: 0)
            ) as? GalleryCell else {
                return UICollectionViewCell()
            }
            cell.viewModel = cellModel
            return cell
        }.disposed(by: disposeBag)

        collectionView.rx.willDisplayCell.bind { [weak self] _, indexPath in
            self?.viewModel.willDisplayCell(at: indexPath)
        }.disposed(by: disposeBag)

        collectionView.rx.didEndDisplayingCell.bind { [weak self] _, indexPath in
            self?.viewModel.didEndDisplayingCell(at: indexPath)
        }.disposed(by: disposeBag)

        collectionView.rx.itemSelected.bind { [weak self] indexPath in
            self?.viewModel.didSelectCell(at: indexPath)
        }.disposed(by: disposeBag)

        viewModel.showActivity.bind { [weak self] show in
            if show {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }.disposed(by: disposeBag)
    }
}

private extension UICollectionViewLayout {
    static var galleryGrid: UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1 / 3),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(1 / 3)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 3
        )
        let spacing = 1.0
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
