//
//  VideoPlayerViewModel.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 10.05.24.
//

import UIKit
import AVFoundation
import RxRelay
import RxSwift
import Combine

final class VideoPlayerViewModel {
    private let isPlayingRelay = BehaviorRelay(value: false)
    private let playerRelay = BehaviorRelay<PlayerInfo?>(value: nil)
    private let router: VideoPlayerRouter

    private var cancellables: Set<AnyCancellable> = []
    private var stopProgressAdjustment = false
    private var wasPlayingBeforeAdjustment = false

    private let asset: AVAsset

    private var avPlayer: AVPlayer? {
        playerRelay.value?.player
    }

    init(
        asset: AVAsset,
        router: VideoPlayerRouter
    ) {
        self.asset = asset
        self.router = router
    }

    private func play() {
        if avPlayer?.didPlayToEnd == true {
            avPlayer?.seek(to: .zero)
        }
        avPlayer?.play()
    }

    private func pause() {
        avPlayer?.pause()
    }

    private func preparePlayerInfo(
        callback: @escaping (PlayerInfo) -> Void
    ) {
        Task(priority: .userInitiated) {
            do {
                async let duration = asset.load(.duration)
                async let tracks = asset.loadTracks(withMediaType: .audio)

                let item = AVPlayerItem(asset: asset)
                let audioTrack = try await tracks.first

                var callbacks = MTAudioProcessingTapCallbacks(
                    version: kMTAudioProcessingTapCallbacksVersion_0,
                    clientInfo: nil,
                    init: nil,
                    finalize: nil,
                    prepare: nil,
                    unprepare: nil,
                    process: { tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut in
                        let sourceAudio = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)

                        guard noErr == sourceAudio else {
                            return
                        }
                        for buffer in UnsafeMutableAudioBufferListPointer(bufferListInOut) {
                            let samples = UnsafeMutableBufferPointer<Float>(
                                start: UnsafeMutablePointer(OpaquePointer(buffer.mData)),
                                count: Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                            )
                            for index in 0 ..< samples.count {
                                samples[index] *= 2.0 // Increase volume by 200%
                            }
                        }
                        numberFramesOut.pointee = numberFrames
                        flagsOut.pointee = flags
                    }
                )

                var tap: Unmanaged<MTAudioProcessingTap>?
                let error = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &tap)

                if error == noErr, let audioTrack, let tapProcessor = tap?.takeRetainedValue() {
                    let inputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
                    inputParameters.audioTapProcessor = tapProcessor

                    let audioMix = AVMutableAudioMix()
                    audioMix.inputParameters = [inputParameters]

                    item.audioMix = audioMix
                }

                let player = AVPlayer(playerItem: item)
                player.actionAtItemEnd = .pause

                let info = PlayerInfo(
                    player: player,
                    item: item,
                    durationSeconds: try await duration.seconds
                )
                await MainActor.run {
                    callback(info)
                }
            } catch {
                await MainActor.run {
                    let item = AVPlayerItem(asset: asset)
                    let player = AVPlayer(playerItem: item)

                    let info = PlayerInfo(
                        player: player,
                        item: item,
                        durationSeconds: 0.0
                    )
                    callback(info)
                }
            }
        }
    }

    private func loadPlayer() {
        preparePlayerInfo { [weak self] playerInfo in
            self?.observePlayback(of: playerInfo.player)

            DispatchQueue.main.async {
                self?.playerRelay.accept(playerInfo)
            }
        }
    }

    private func observePlayback(of player: AVPlayer) {
        let didPlayToEndPublisher = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime
        )
        didPlayToEndPublisher.subscribe(on: DispatchQueue.main).sink { [weak self] _ in
            self?.stopProgressAdjustment = true
        }.store(in: &cancellables)

        let timeStatusPublisher = player.publisher(for: \.timeControlStatus)

        timeStatusPublisher.sink { [weak self] status in
            switch status {
            case .paused:
                self?.isPlayingRelay.accept(false)

            case .playing:
                self?.isPlayingRelay.accept(true)

            default: break
            }
        }.store(in: &cancellables)
    }

    private func adjustProgress(with durationPercent: Double) {
        guard let avPlayer, stopProgressAdjustment == false else {
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let videoDurationSec = avPlayer.currentItem?.duration.seconds ?? 0
        let seekDuration = videoDurationSec * durationPercent
        let newTime = playerCurrentTime + seekDuration
        let timeInSeconds = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1000)

        avPlayer.seek(to: timeInSeconds, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

extension VideoPlayerViewModel: VideoPlayerViewModelProtocol {
    var player: Observable<PlayerInfo?> {
        playerRelay.asObservable()
    }

    var playPauseButtonImage: Observable<UIImage> {
        isPlayingRelay.observe(on: MainScheduler.instance).map { isPlaying in
            isPlaying ? .Player.pause : .Player.play
        }
    }

    func viewDidLoad() {
        loadPlayer()
    }

    func viewDidAppear() {
        if avPlayer?.status == .readyToPlay {
            play()
        }
    }

    func didTapPlayPauseButton() {
        let isPlaying = isPlayingRelay.value

        isPlaying ? pause() : play()
    }

    func didTapClose() {
        pause()
        router.close()
    }

    func didStartProgressAdjustment() {
        stopProgressAdjustment = false
        wasPlayingBeforeAdjustment = isPlayingRelay.value

        avPlayer?.pause()
    }

    func didChangeProgress(with percent: Double) {
        adjustProgress(with: percent)
    }

    func didFinishProgressAdjustment() {
        stopProgressAdjustment = false

        if wasPlayingBeforeAdjustment {
            avPlayer?.play()
        }
    }
}

private extension UIImage {
    enum Player {
        static var play: UIImage {
            .init(systemName: "play")!
        }

        static var pause: UIImage {
            .init(systemName: "pause")!
        }
    }
}

private extension AVPlayer {
    var didPlayToEnd: Bool {
        let currentTime = self.currentTime().seconds
        let duration = self.currentItem?.duration.seconds ?? 0

        return currentTime >= duration
    }
}
