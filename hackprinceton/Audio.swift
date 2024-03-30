//
//  Audio.swift
//  hackprinceton
//
//  Created by Joy Liu on 3/30/24.
//

import Foundation
import AVFoundation

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String, numLoops: Int) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.numberOfLoops = numLoops
            audioPlayer?.play()
        } catch {
            print("ERROR")
        }
    }
}
