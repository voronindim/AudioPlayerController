//
//  AudioPlayerControllerStarter.swift
//  AudioPlayerController
//
//  Created by Dmitrii Voronin on 15.04.2021.
//

import Foundation
import AVFoundation

protocol AudioPlayerControllerStarter {
    func startPlay(url: URL, startTime: CMTime)
}
