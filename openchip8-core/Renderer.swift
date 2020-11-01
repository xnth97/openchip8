//
//  Renderer.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import Foundation
import SpriteKit

public protocol RendererProtocol {
    @discardableResult
    func setPixel(x: Int, y: Int) -> Bool
    func render()
    func clear()
}

public class Renderer: RendererProtocol {
    
    private static let width = 64
    private static let height = 32
    
    private let pixelDimension: CGFloat
    
    public var backgroundColor: NSColor {
        didSet {
            render()
        }
    }
    public var pixelColor: NSColor {
        didSet {
            render()
        }
    }
    
    private var pixels: [[Pixel]] = []
    
    public let scene: SKScene
    
    private struct Pixel {
        var value: UInt8
        let node: SKSpriteNode
        
        init(color: NSColor, dimension: CGFloat) {
            value = 0
            node = SKSpriteNode(color: color,
                                size: CGSize(width: dimension, height: dimension))
            node.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        }
    }
    
    public init(pixelDimension: CGFloat = 10.0,
                backgroundColor: NSColor = .black,
                pixelColor: NSColor = .white) {
        self.pixelDimension = pixelDimension
        self.backgroundColor = backgroundColor
        self.pixelColor = pixelColor
        
        scene = SKScene(size: CGSize(width: CGFloat(Self.width) * pixelDimension,
                                     height: CGFloat(Self.height) * pixelDimension))
        scene.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        scene.backgroundColor = backgroundColor
        
        initPixels()
    }
    
    /// Toggle a pixel. Note that origin point is at top left corner.
    /// - Parameters:
    ///   - x: X coordinate.
    ///   - y: Y coordinate.
    /// - Returns: If the pixel is erased or not.
    @discardableResult
    public func setPixel(x: Int, y: Int) -> Bool {
        var col = x
        var row = y
        
        /// Wrap around to the opposite side if pixel is outside of the bounds
        while col >= Self.width {
            col -= Self.width
        }
        while col < 0 {
            col += Self.width
        }
        while row >= Self.height {
            row -= Self.height
        }
        while row < 0 {
            row += Self.height
        }
        
        /// XOR
        pixels[row][col].value ^= UInt8(1)
        
        /// Returns whether a pixel was erased or not
        return pixels[row][col].value == UInt8(0)
    }
    
    public func render() {
        for row in 0 ..< Self.height {
            for col in 0 ..< Self.width {
                let pixel = pixels[row][col]
                pixel.node.color = pixel.value == UInt8(1) ? pixelColor : backgroundColor
            }
        }
    }
    
    public func clear() {
        for row in 0 ..< Self.height {
            for col in 0 ..< Self.width {
                pixels[row][col].node.color = backgroundColor
            }
        }
    }
    
    private func initPixels() {
        for row in 0 ..< Self.height {
            pixels.append(Array<Pixel>())
            for col in 0 ..< Self.width {
                let pixel = Pixel(color: backgroundColor, dimension: pixelDimension)
                pixel.node.position = transformCoordinates(x: col, y: row)
                scene.addChild(pixel.node)
                pixels[row].append(pixel)
            }
        }
    }
    
    private func transformCoordinates(x: Int, y: Int) -> CGPoint {
        let xCor = CGFloat(x) * pixelDimension
        let yCor = CGFloat(-y) * pixelDimension
        return CGPoint(x: xCor, y: yCor)
    }
    
}
