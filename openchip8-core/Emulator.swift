//
//  Emulator.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import Foundation

public class Emulator {
    
    private let fps = 60
    private let vm: VirtualMachine
    
    private let timerQueue = DispatchQueue(label: "emulator_timer_queue")
    private var timer: DispatchSourceTimer?
    
    public init(renderer: RendererProtocol,
                keyboard: KeyboardProtocol,
                speaker: SpeakerProtocol) {
        vm = VirtualMachine(renderer: renderer, keyboard: keyboard, speaker: speaker)
        
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "SUBMARINE", withExtension: "")!)
        vm.loadRom(from: data)
    }
    
    public func start() {
        if timer != nil {
            stop()
        }
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: 1.0 / Double(fps))
        timer?.setEventHandler(handler: {
            self.vm.cycle()
        })
        timer?.resume()
    }
    
    public func stop() {
        timer?.cancel()
        timer = nil
    }
    
}
