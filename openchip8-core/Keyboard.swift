//
//  Keyboard.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import Foundation
import AppKit

public typealias KeyCode = UInt8

public protocol KeyboardProtocol {
    func isKeyPressed(_ keyCode: KeyCode) -> Bool
    func handleNextKeyPress(_ block: @escaping (KeyCode) -> Void)
}

public let QwertyKeyboardMap: [UInt16: KeyCode] = [
    18: 0x1, // 1
    19: 0x2, // 2
    20: 0x3, // 3
    21: 0xc, // 4
    12: 0x4, // Q
    13: 0x5, // W
    14: 0x6, // E
    15: 0xD, // R
    0: 0x7,  // A
    1: 0x8,  // S
    2: 0x9,  // D
    3: 0xE,  // F
    6: 0xA,  // Z
    7: 0x0,  // X
    8: 0xB,  // C
    9: 0xF,  // V
]

public class Keyboard: KeyboardProtocol {

    private var keysPressed: [KeyCode: Bool] = [:]
    private var nextKeyPressBlock: ((KeyCode) -> Void)?

    public init() {
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            self.handleKeyUp(with: event)
            /// return nil to tell OS that event is handled.
            return nil
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyDown(with: event)
            return nil
        }
    }

    public func isKeyPressed(_ keyCode: KeyCode) -> Bool {
        return keysPressed[keyCode] ?? false
    }

    public func handleNextKeyPress(_ block: @escaping (KeyCode) -> Void) {
        nextKeyPressBlock = block
    }

    private func handleKeyUp(with event: NSEvent) {
        guard let keyCode = getKeyCode(from: event) else {
            return
        }
        keysPressed[keyCode] = false
    }

    private func handleKeyDown(with event: NSEvent) {
        guard let keyCode = getKeyCode(from: event) else {
            return
        }
        keysPressed[keyCode] = true

        if let nextKeyBlock = nextKeyPressBlock {
            nextKeyBlock(keyCode)
            nextKeyPressBlock = nil
        }
    }

    private func getKeyCode(from event: NSEvent) -> KeyCode? {
        return QwertyKeyboardMap[event.keyCode]
    }

}
