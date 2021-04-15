//
//  AudioPlayerFactory.swift
//  AudioPlayerController
//
//  Created by Dmitrii Voronin on 15.04.2021.
//

import Foundation
import AVFoundation

final class AudioPLayerFactory {
    
    func avPlayer(url: URL) -> AVPlayer {
        let avPlayerItem = AVPlayerItem(asset: AVAsset(url: url))
        return AVPlayer(playerItem: avPlayerItem)
    }
}
