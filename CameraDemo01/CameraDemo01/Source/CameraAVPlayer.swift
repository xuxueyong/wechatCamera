//
//  CameraAVPlayer.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/12.
//

import Foundation
import AVFoundation

class CameraAVPlayer {
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var playerLayer: AVPlayerLayer?
    
    init(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidFinished), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    func replaceVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidFinished), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraAVPlayer {
    @objc
    func playbackDidFinished() {
        let time = CMTime(value: 0, timescale: 1)
        player?.seek(to: time, toleranceBefore: time, toleranceAfter: time, completionHandler: {[weak self] _ in
            guard let self = self else { return }
            self.player?.play()
        })
    }
}
