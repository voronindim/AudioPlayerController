//
//  AudioPlayerController.swift
//  AudioPlayerController
//
//  Created by Dmitrii Voronin on 15.04.2021.
//

import Foundation
import AVFoundation
import RxSwift

protocol AudioPlayerController {
    var duration: Observable<Float64?> { get }
    var currentDuration: Observable<Float64?> { get }
    var playerStatus: Observable<AudioPlayerStatus> { get }
    var rate: Observable<Float> { get }
    
    func play()
    func pause()
    func rollBack()
    func rollForward()
    func currentDurationDidChange(newValue value: Float64)
}

final class AudioPlayerControllerImpl {
    
    // MARK: - Private properties
    
    private let _duration = BehaviorSubject<Float64?>(value: nil)
    private let _currentDuration = BehaviorSubject<Float64?>(value: nil)
    private let _playerStatus = BehaviorSubject<AudioPlayerStatus>(value: .none)
    private let _rate = BehaviorSubject<Float>(value: 1.0)
    private let audioPlayerFactory: AudioPLayerFactory
    private let kRateValues: [Float]
    private let kRollTime: Float64
    private var player: AVPlayer?
    private var lastRate: Float = 1.0
    
    // MARK: - Initialize
    
    init(audioPlayerFactory: AudioPLayerFactory, kRateValues: [Float], kRollTime: Float64) {
        self.audioPlayerFactory = audioPlayerFactory
        self.kRateValues = kRateValues
        self.kRollTime = kRollTime
    }
    
}

// MARK: - AudioPlayerController

extension AudioPlayerControllerImpl: AudioPlayerController {
    var duration: Observable<Float64?> {
        _duration
    }
    
    var currentDuration: Observable<Float64?> {
        _currentDuration
    }
    
    var playerStatus: Observable<AudioPlayerStatus> {
        _playerStatus
    }
    
    var rate: Observable<Float> {
        _rate
    }
    
    func play() {
        guard let player = player else {
            return
        }
        player.play()
        player.rate = lastRate
        _playerStatus.onNext(.play)
    }
    
    func pause() {
        guard let player = player else {
            return
        }
        lastRate = player.rate
        player.pause()
        _playerStatus.onNext(.pause)
    }
    
    func changeRate() {
        guard let player = player else {
            return
        }
        guard let newValue = nextRate else {
            return
        }
        player.rate = newValue
        _rate.onNext(newValue)
    }
    
    func rollBack() {
        guard let player = player else {
            return
        }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime - kRollTime < 0 ? 0 : currentTime - kRollTime
        let time2 = newTime.toCMTime
        player.seek(to: time2, toleranceBefore: .zero, toleranceAfter: .zero)
        _currentDuration.onNext(time2.toFloat64)
    }
    
    func rollForward() {
        guard let player = player, let duration = player.currentItem?.duration else {
            return
        }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + kRollTime
        if newTime < CMTimeGetSeconds(duration) - kRollTime {
            let time2 = newTime.toCMTime
            player.seek(to: time2, toleranceBefore: .zero, toleranceAfter: .zero)
            _currentDuration.onNext(time2.toFloat64)
        }
    }
    
    func currentDurationDidChange(newValue value: Float64) {
        guard let player = player else {
            return
        }
        let newTime = value.toCMTime
        player.seek(to: newTime)
        _currentDuration.onNext(newTime.toFloat64)
    }
    
    // MARK: - Private methods
    
    private func addPeriodicTimeObserver() {
        guard let player = player else {
            return
        }
        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: DispatchQueue.main, using: { time in
            self._currentDuration.onNext(time.toFloat64)
        })
    }
    
}

// MARK: - AudioPlayerController

extension AudioPlayerControllerImpl: AudioPlayerControllerStarter {
    func startPlay(url: URL, startTime: CMTime) {
        player = audioPlayerFactory.avPlayer(url: url)
        player?.seek(to: startTime)
        player?.play()
        addPeriodicTimeObserver()
    }
}

// MARK: -

extension AudioPlayerControllerImpl {
    private var nextRate: Float? {
        guard let currentRate = try? _rate.value() else {
            return nil
        }
        guard let index = kRateValues.firstIndex(where: { $0 == currentRate }) else {
            return nil
        }
        return index > kRateValues.count - 1 ? kRateValues.first : kRateValues[index + 1]
    }
}

fileprivate extension Float64 {
    var toCMTime: CMTime {
        CMTimeMake(value: Int64(self * 1000 as Float64), timescale: 1000)
    }
}

fileprivate extension CMTime {
    var toFloat64: Float64 {
        Float64(CMTimeGetSeconds(self))
    }
}
