//
//  ViewController.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 10.05.24.
//

import UIKit
import SnapKit
import AVFoundation
import RxSwift
import RxCocoa
import MediaPlayer

protocol VideoPlayerViewModelProtocol {
    typealias PlayerInfo = VideoPlayerViewController.PlayerInfo

    var player: Observable<PlayerInfo?> { get }
    var playPauseButtonImage: Observable<UIImage> { get }

    func viewDidLoad()
    func viewDidAppear()

    func didTapPlayPauseButton()
    func didTapClose()

    func didStartProgressAdjustment()
    func didChangeProgress(with percent: Double)
    func didFinishProgressAdjustment()
}

extension VideoPlayerViewController {
    struct PlayerInfo {
        let player: AVPlayer
        let item: AVPlayerItem
        let durationSeconds: TimeInterval
    }
}

final class VideoPlayerViewController: UIViewController {
    var viewModel: VideoPlayerViewModelProtocol!

    private let actionsContainer = UIView()
    private let playPauseButton = ExtendedButton()
    private let videoView = VideoView()
    private let progressBarContainer = UIView()
    private let panRecognizer = UIPanGestureRecognizer()
    private let closeButton = UIButton(type: .close)

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear()
    }

    private func setupProgressBar(for player: PlayerInfo) {
        progressBarContainer.subviews.forEach { $0.removeFromSuperview() }

        let progressBar = ItemProgressBar(
            playerItem: player.item,
            duration: player.durationSeconds
        )
        progressBar.fill(in: progressBarContainer)
    }
}

private extension VideoPlayerViewController {
    func bindViewModel() {
        viewModel.player.bind { [weak self] playerInfo in
            guard let playerInfo else {
                return
            }
            self?.videoView.player = playerInfo.player
            self?.setupProgressBar(for: playerInfo)
        }.disposed(by: disposeBag)

        viewModel.playPauseButtonImage
            .bind(to: playPauseButton.rx.image(for: .normal))
            .disposed(by: disposeBag)

        playPauseButton.rx.tap.bind { [weak self] in
            self?.viewModel.didTapPlayPauseButton()
        }.disposed(by: disposeBag)

        closeButton.rx.tap.bind { [weak self] in
            self?.viewModel.didTapClose()
        }.disposed(by: disposeBag)
    }

    func setupSubviews() {
        view.backgroundColor = .black

        videoView.layout(in: view) { make in
            make.edges.equalToSuperview()
        }
        actionsContainer.layout(in: view) { make in
            make.height.equalTo(50)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        let effectsView = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemThinMaterialDark)
        )
        view.insertSubview(effectsView, belowSubview: actionsContainer)
        effectsView.snp.makeConstraints { make in
            make.horizontalEdges.top.equalTo(actionsContainer)
            make.bottom.equalTo(view)
        }
        playPauseButton.layout(in: actionsContainer) { make in
            make.centerX.centerY.equalToSuperview()
        }
        closeButton.layout(in: view) { make in
            make.top.left.equalTo(view.safeAreaLayoutGuide).inset(20.0)
        }
        progressBarContainer.layout(in: actionsContainer) { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(4)
        }
        actionsContainer.addGestureRecognizer(panRecognizer)
        panRecognizer.addTarget(self, action: #selector(panRecognized))
    }

    @objc
    private func panRecognized(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            viewModel.didStartProgressAdjustment()

        case .changed:
            let translation = sender.translation(in: actionsContainer).x
            let percentChange = translation / actionsContainer.bounds.width
            sender.setTranslation(.zero, in: actionsContainer)

            viewModel.didChangeProgress(with: percentChange)

        case .ended, .cancelled, .failed:
            viewModel.didFinishProgressAdjustment()

        default: break
        }
    }
}
