//
//  ViewController.swift
//  openchip8
//
//  Created by Yubo Qin on 10/30/20.
//

import Cocoa
import SpriteKit

class MainViewController: NSViewController {
    
    private let renderer = Renderer()
    private let skView = SKView()
    
    private var keysPressed: [KeyCode: Bool] = [:]
    private var nextKeyPressBlock: ((KeyCode) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubview(skView)
        skView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        skView.presentScene(renderer.scene)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            self.handleKeyUp(with: event)
            /// return nil to tell OS that event is handled.
            return nil
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyDown(with: event)
            return nil
        }
        
        let emulator = Emulator(renderer: renderer, keyboard: self, speaker: Speaker())
        emulator.start()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension MainViewController: KeyboardProtocol {
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
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
    
    func isKeyPressed(_ keyCode: KeyCode) -> Bool {
        return keysPressed[keyCode] ?? false
    }
    
    func handleNextKeyPress(_ block: @escaping (KeyCode) -> Void) {
        nextKeyPressBlock = block
    }
    
    private func getKeyCode(from event: NSEvent) -> KeyCode? {
        return QwertyKeyboardMap[event.keyCode]
    }
    
}

