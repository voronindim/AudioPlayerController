//
//  AudioViewModel.swift
//  AudioPlayerController
//
//  Created by Dmitrii Voronin on 15.04.2021.
//

import Foundation
import RxSwift
import UIKit
import AVFoundation

final class AudioViewModel {
    
    // MARK: - Private properties
    
    private let audioPlayerController: AudioPlayerController
    private let _title = BehaviorSubject<String?>(value: nil)
    private let _duration = BehaviorSubject<String?>(value: nil)
    private let _currentDuration = BehaviorSubject<String?>(value: nil)
    private let _rate = BehaviorSubject<String?>(value: nil)
    private let _playButtonImage = BehaviorSubject<UIImage?>(value: nil)
    private let disposeBag = DisposeBag()
    
    private var playerStatus: AudioPlayerStatus = .none {
        didSet {
            if let image = createImageForAudioStatus() {
                _playButtonImage.onNext(image)
            }
        }
    }
    
    // MARK: - Initialize
    
    init(audioPlayerController: AudioPlayerController) {
        self.audioPlayerController = audioPlayerController
    }
    
    // MARK: - Public methods
    
    func play() {
        audioPlayerController.play()
    }
    
    func pause() {
        audioPlayerController.pause()
    }
    
    func rollBack() {
        audioPlayerController.rollBack()
    }
    
    func rollForward() {
        audioPlayerController.rollForward()
    }
    
    func currentDurationDidChange(newValue value: Float64) {
        audioPlayerController.currentDurationDidChange(newValue: value)
    }
    
    // MARK: - Private methods
    
    private func subscriveOnAudioPlayerController() {
        audioPlayerController.duration.distinctUntilChanged().subscribe(onNext: { time in
            self.setDuration(time: time)
        }).disposed(by: disposeBag)
        
        audioPlayerController.currentDuration.distinctUntilChanged().subscribe(onNext: {time in
            self.setCurrentDuration(time: time)
        }).disposed(by: disposeBag)
        
        audioPlayerController.playerStatus.distinctUntilChanged().subscribe(onNext: { status in
            self.playerStatus = status
        }).disposed(by: disposeBag)
        
        audioPlayerController.rate.distinctUntilChanged().subscribe(onNext: { rate in
            self.setRate(rate: rate)
        }).disposed(by: disposeBag)
    }
    
    private func setDuration(time: CMTime?) {
        guard let time = time else {
            return
        }
        _duration.onNext(time.durationText)
    }
    
    private func setCurrentDuration(time: CMTime?) {
        guard let time = time else {
            return
        }
        _currentDuration.onNext(time.durationText)
    }
    
    private func setRate(rate: Float?) {
        guard let rate = rate else {
            return
        }
        _rate.onNext("x \(rate)")
    }
    
    private func createImageForAudioStatus() -> UIImage? {
        switch playerStatus {
        case .pause:
            return UIImage(named: "icon-play")!
        case .play:
            return UIImage(named: "icon-pause")!
        default:
            return nil
        }
    }
}

// MARK: -

extension AudioViewModel {
    var title: Observable<String?> {
        _title
    }
    
    var duration: Observable<String?> {
        _duration
    }
    
    var currentDuration: Observable<String?> {
        _currentDuration
    }
    
    var rate: Observable<String?> {
        _rate
    }
    
    var playButtonImage: Observable<UIImage?> {
        _playButtonImage
    }
}

fileprivate extension CMTime {
    var durationText:String {
        let totalSeconds = Int(CMTimeGetSeconds(self))
        let hours:Int = Int(totalSeconds / 3600)
        let minutes:Int = Int(totalSeconds % 3600 / 60)
        let seconds:Int = Int((totalSeconds % 3600) % 60)

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
