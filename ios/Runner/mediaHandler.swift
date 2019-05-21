//
//  mediaHandler.swift
//  Runner
//
//  Created by beddoww on 5/20/19.
//

import Foundation
import AVKit




class mediaHandler{
    var player: AVPlayer?
    
    init(streamURL: String){
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            player = AVPlayer(url: URL.init(string: streamURL)!)
        } catch {
            print("Got audio initialization error");
        }
    }
    
    func play(){
        player.seek(player.duration)
        player.play()
    }
    func pause(){
        player.pause()
    }
}

