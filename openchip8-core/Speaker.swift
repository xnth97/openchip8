//
//  Speaker.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import AppKit

public protocol SpeakerProtocol {
    func play(frequency: Float)
    func stop()
}

public class Speaker: SpeakerProtocol {
    
    private let sound = NSSound(named: "Ping")
    
    public func play(frequency: Float) {
        sound?.play()
    }
    
    public func stop() {
        sound?.stop()
    }
    
}
