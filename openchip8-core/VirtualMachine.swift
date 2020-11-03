//
//  VirtualMachine.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import Foundation

public class VirtualMachine {
    
    let renderer: RendererProtocol
    let keyboard: KeyboardProtocol
    let speaker: SpeakerProtocol
    
    /// 4KB of memory
    private var memory: [UInt8] = Array(repeating: 0, count: 4096)
    
    /// 16 8-bit Vx registers
    private var vx_reg: [UInt8] = Array(repeating: 0, count: 16)
    
    /// 16-bit register I to store memory address
    private var i_reg: UInt16 = 0
    
    /// Timer for delay
    private var delayTimer: UInt8 = 0
    
    /// Timer for sound
    private var soundTimer: UInt8 = 0
    
    /// Program counter that stores the address currently being executed
    private var pc: UInt16 = 0x200
    
    /// Stack of CPU
    private var stack: [UInt16] = []
    
    private var paused = false
    private var speed = 10
    
    public init(renderer: RendererProtocol,
                keyboard: KeyboardProtocol,
                speaker: SpeakerProtocol) {
        self.renderer = renderer
        self.keyboard = keyboard
        self.speaker = speaker
        
        loadSpritesIntoMemory()
    }
    
    // MARK: - APIs
    
    public func loadRom(from data: Data) {
        let array: [UInt8] = Array<UInt8>(data)
        loadProgramIntoMemory(array)
    }
    
    public func cycle() {
        for _ in 0 ..< speed {
            if paused {
                continue
            }
            
            /// Combine two 8-bit values into one 16-bit instruction
            let opCode: UInt16 = (UInt16(memory[Int(pc)]) << 8 | UInt16(memory[Int(pc) + 1]))
            executeInstruction(opCode)
        }
        
        if !paused {
            updateTimers()
        }
        
        playSound()
        renderer.render()
    }
    
    // MARK: - Private
    
    private func loadSpritesIntoMemory() {
        let sprites: [UInt8] = [
            0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
            0x20, 0x60, 0x20, 0x20, 0x70, // 1
            0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
            0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
            0x90, 0x90, 0xF0, 0x10, 0x10, // 4
            0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
            0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
            0xF0, 0x10, 0x20, 0x40, 0x40, // 7
            0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
            0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
            0xF0, 0x90, 0xF0, 0x90, 0x90, // A
            0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
            0xF0, 0x80, 0x80, 0x80, 0xF0, // C
            0xE0, 0x90, 0x90, 0x90, 0xE0, // D
            0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
            0xF0, 0x80, 0xF0, 0x80, 0x80, // F
        ];
        
        /// Sprites are stored in the interpreter section of memory (0x000 - 0x1FF)
        for i in 0 ..< sprites.count {
            memory[i] = sprites[i]
        }
    }
    
    private func loadProgramIntoMemory(_ program: [UInt8]) {
        /// Most programs start at 0x200
        for i in 0 ..< program.count {
            memory[0x200 + i] = program[i]
        }
    }
    
    /// Ref: http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#3.0
    private func executeInstruction(_ opCode: UInt16) {
        /// Instructions are 2 bytes long. Move pc to next instruction
        pc += 2
        
        /// nnn or addr - A 12-bit value, the lowest 12 bits of the instruction
        let nnn = (0xFFF & opCode)
        
        /// n or nibble - A 4-bit value, the lowest 4 bits of the instruction
        let n = (0xF & opCode)
        
        /// x - A 4-bit value, the lower 4 bits of the high byte of the instruction
        let x = Int(0xF00 & opCode) >> 8
        
        /// y - A 4-bit value, the upper 4 bits of the low byte of the instruction
        let y = Int(0xF0 & opCode) >> 4
        
        /// kk or byte - An 8-bit value, the lowest 8 bits of the instruction
        let kk = UInt8(0xFF & opCode)
        
        switch 0xF000 & opCode {
        case 0x0000:
            switch opCode {
            case 0x00E0:
                /// 00E0 - CLS
                /// Clear the display.
                renderer.clear()
            case 0x00EE:
                /// 00EE - RET
                /// Return from a subroutine.
                if let last = stack.popLast() {
                    pc = last
                }
            default:
                break
            }
        case 0x1000:
            /// 1nnn - JP addr
            /// Jump to location nnn.
            pc = nnn
        case 0x2000:
            /// 2nnn - CALL addr
            /// Call subroutine at nnn.
            stack.append(pc)
            pc = nnn
        case 0x3000:
            /// 3xkk - SE Vx, byte
            /// Skip next instruction if Vx = kk.
            if vx_reg[x] == kk {
                pc += 2
            }
        case 0x4000:
            /// 4xkk - SNE Vx, byte
            /// Skip next instruction if Vx != kk.
            if vx_reg[x] != kk {
                pc += 2
            }
        case 0x5000:
            /// 5xy0 - SE Vx, Vy
            /// Skip next instruction if Vx = Vy.
            if vx_reg[x] == vx_reg[y] {
                pc += 2
            }
        case 0x6000:
            /// 6xkk - LD Vx, byte
            /// Set Vx = kk.
            vx_reg[x] = kk
        case 0x7000:
            /// 7xkk - ADD Vx, byte
            /// Set Vx = Vx + kk.
            vx_reg[x] = vx_reg[x] &+ kk
        case 0x8000:
            switch n {
            case 0x0:
                /// 8xy0 - LD Vx, Vy
                /// Set Vx = Vy.
                vx_reg[x] = vx_reg[y]
            case 0x1:
                /// 8xy1 - OR Vx, Vy
                /// Set Vx = Vx OR Vy.
                vx_reg[x] |= vx_reg[y]
            case 0x2:
                /// 8xy2 - AND Vx, Vy
                /// Set Vx = Vx AND Vy.
                vx_reg[x] &= vx_reg[y]
            case 0x3:
                /// 8xy3 - XOR Vx, Vy
                /// Set Vx = Vx XOR Vy.
                vx_reg[x] ^= vx_reg[y]
            case 0x4:
                /// 8xy4 - ADD Vx, Vy
                /// Set Vx = Vx + Vy, set VF = carry.
                let sum = UInt16(vx_reg[x]) + UInt16(vx_reg[y])
                vx_reg[x] = UInt8(sum & 0xFF)
                if sum > 0xFF {
                    vx_reg[0xF] = 1
                } else {
                    vx_reg[0xF] = 0
                }
            case 0x5:
                /// 8xy5 - SUB Vx, Vy
                /// Set Vx = Vx - Vy, set VF = NOT borrow.
                if vx_reg[x] > vx_reg[y] {
                    vx_reg[0xF] = 1
                } else {
                    vx_reg[0xF] = 0
                }
                vx_reg[x] = vx_reg[x] &- vx_reg[y]
            case 0x6:
                /// 8xy6 - SHR Vx {, Vy}
                /// Set Vx = Vx SHR 1.
                if (0x1 & vx_reg[x]) == 1 {
                    vx_reg[0xF] = 1
                } else {
                    vx_reg[0xF] = 0
                }
                vx_reg[x] >>= 1
            case 0x7:
                /// 8xy7 - SUBN Vx, Vy
                /// Set Vx = Vy - Vx, set VF = NOT borrow.
                if vx_reg[y] > vx_reg[x] {
                    vx_reg[0xF] = 1
                } else {
                    vx_reg[0xF] = 0
                }
                vx_reg[x] = vx_reg[y] &- vx_reg[x]
            case 0xE:
                /// 8xyE - SHL Vx {, Vy}
                /// Set Vx = Vx SHL 1.
                if (vx_reg[x] >> 7) == 1 {
                    vx_reg[0xF] = 1
                } else {
                    vx_reg[0xF] = 0
                }
                vx_reg[x] <<= 1
            default:
                break
            }
        case 0x9000:
            /// 9xy0 - SNE Vx, Vy
            /// Skip next instruction if Vx != Vy.
            if vx_reg[x] != vx_reg[y] {
                pc += 2
            }
        case 0xA000:
            /// Annn - LD I, addr
            /// Set I = nnn.
            i_reg = nnn
        case 0xB000:
            /// Bnnn - JP V0, addr
            /// Jump to location nnn + V0.
            pc = nnn + UInt16(vx_reg[0])
        case 0xC000:
            /// Cxkk - RND Vx, byte
            /// Set Vx = random byte AND kk.
            let random = UInt8.random(in: 0 ... 0xFF)
            vx_reg[x] = random & kk
        case 0xD000:
            /// Dxyn - DRW Vx, Vy, nibble
            /// Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
            let width: UInt8 = 8
            let height = UInt8(n)
            vx_reg[0xF] = 0
            
            for row in 0 ..< height {
                var sprite = memory[Int(i_reg) + Int(row)]
                
                for col in 0 ..< width {
                    /// If the bit (sprite) is not 0, render/erase the pixel
                    if sprite & 0x80 != 0 {
                        let xCor = Int(vx_reg[x] &+ col)
                        let yCor = Int(vx_reg[y] &+ row)
                        
                        /// If setPixel returns 1, which means a pixel was erased, set VF to 1
                        if renderer.setPixel(x: xCor, y: yCor) {
                            vx_reg[0xF] = 1
                        }
                    }
                    
                    /// Shift sprite left 1.
                    sprite <<= 1
                }
            }
        case 0xE000:
            switch kk {
            case 0x9E:
                /// Ex9E - SKP Vx
                /// Skip next instruction if key with the value of Vx is pressed.
                if keyboard.isKeyPressed(vx_reg[x]) {
                    pc += 2
                }
            case 0xA1:
                /// ExA1 - SKNP Vx
                /// Skip next instruction if key with the value of Vx is not pressed.
                if !keyboard.isKeyPressed(vx_reg[x]) {
                    pc += 2
                }
            default:
                break
            }
        case 0xF000:
            switch kk {
            case 0x07:
                /// Fx07 - LD Vx, DT
                /// Set Vx = delay timer value.
                vx_reg[x] = delayTimer
            case 0x0A:
                /// Fx0A - LD Vx, K
                /// Wait for a key press, store the value of the key in Vx.
                paused = true
                keyboard.handleNextKeyPress { keyCode in
                    self.vx_reg[x] = keyCode
                }
            case 0x15:
                /// Fx15 - LD DT, Vx
                /// Set delay timer = Vx.
                delayTimer = vx_reg[x]
            case 0x18:
                /// Fx18 - LD ST, Vx
                /// Set sound timer = Vx.
                soundTimer = vx_reg[x]
            case 0x1E:
                /// Fx1E - ADD I, Vx
                /// Set I = I + Vx.
                i_reg = i_reg &+ UInt16(vx_reg[x])
            case 0x29:
                /// Fx29 - LD F, Vx
                /// Set I = location of sprite for digit Vx.
                /// Each sprite is 5 bytes long
                i_reg = UInt16(vx_reg[x]) * 5
            case 0x33:
                /// Fx33 - LD B, Vx
                /// Store BCD representation of Vx in memory locations I, I+1, and I+2.
                let indexI = Int(i_reg)
                memory[indexI] = vx_reg[x] / 100
                memory[indexI + 1] = (vx_reg[x] % 100) / 10
                memory[indexI + 2] = vx_reg[x] % 10
            case 0x55:
                /// Fx55 - LD [I], Vx
                /// Store registers V0 through Vx in memory starting at location I.
                for idx in 0 ..< x {
                    memory[Int(i_reg) + idx] = vx_reg[idx]
                }
            case 0x65:
                /// Fx65 - LD Vx, [I]
                /// Read registers V0 through Vx from memory starting at location I.
                for idx in 0 ..< x {
                    vx_reg[idx] = memory[Int(i_reg) + idx]
                }
                
            default:
                break
            }
            
        default:
            break
        }
        
    }
    
    /// Each timer decrements by 1 at a rate of 60hz
    private func updateTimers() {
        if delayTimer > 0 {
            delayTimer -= 1
        }
        if soundTimer > 0 {
            soundTimer -= 1
        }
    }
    
    private func playSound() {
        if soundTimer > 0 {
            speaker.play()
        } else {
            speaker.stop()
        }
    }
    
}
