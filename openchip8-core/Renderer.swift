//
//  Renderer.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import AppKit
import Combine

public protocol RendererProtocol {
    @discardableResult
    func setPixel(x: Int, y: Int) -> Bool
    func render()
    func clear()
}

public class Renderer: ObservableObject, RendererProtocol {
    
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
    
    public struct Pixel: Hashable {
        let x: Int
        let y: Int
    }

    /// Object to drive UI change.
    @Published public private(set) var pixels: Set<Pixel> = []
    /// Underlying storage.
    private var _p: Set<Pixel> = []
    
    public init(pixelDimension: CGFloat = 10.0,
                backgroundColor: NSColor = .black,
                pixelColor: NSColor = .white) {
        self.pixelDimension = pixelDimension
        self.backgroundColor = backgroundColor
        self.pixelColor = pixelColor
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
        let pixel = Pixel(x: col, y: row)
        if _p.contains(pixel) {
            /// Returns whether a pixel was erased or not
            _p.remove(pixel)
            return true
        } else {
            _p.insert(pixel)
            return false
        }
    }
    
    public func render() {
        DispatchQueue.main.async {
            self.pixels = self._p
        }
    }
    
    public func clear() {
        DispatchQueue.main.async {
            self.pixels = []
            self._p = []
        }
    }
    
    private func transformCoordinates(x: Int, y: Int) -> CGPoint {
        let xCor = CGFloat(x) * pixelDimension
        let yCor = CGFloat(y) * pixelDimension
        return CGPoint(x: xCor, y: yCor)
    }

    public func pixelToRect(_ pixel: Pixel) -> CGRect {
        return CGRect(
            origin: transformCoordinates(x: pixel.x, y: pixel.y),
            size: CGSize(width: pixelDimension, height: pixelDimension))
    }
    
}
