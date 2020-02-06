//
//  Speaker.swift
//  vWalkAssistant
//
//  Created by Allen Zhao on 2/4/20.
//  Copyright © 2020 Amit Gupta. All rights reserved.
//

import Foundation
import AVFoundation

class Speaker {
    
    private let synthesizer = AVSpeechSynthesizer()
    
    static let shared = Speaker()
    
    private func prepare(text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        return utterance
    }
    
    func announce(text: String) {
        synthesizer.speak(prepare(text: text))
    }
}
