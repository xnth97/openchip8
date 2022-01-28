//
//  Renderer.swift
//  openchip8-core
//
//  Created by Yubo Qin on 10/30/20.
//

import AppKit

public protocol RendererProtocol {
    @discardableResult
    func setPixel(x: Int, y: Int) -> Bool
    func render()
    func clear()
}

public class Renderer: RendererProtocol {
    
    private static let width = 64
    private static let height = 32
    
    fileprivate let pixelDimension: CGFloat
    
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

    public lazy var view = RendererView(renderer: self)
    fileprivate var pixels: Set<Pixel> = Set()
    
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
        if pixels.contains(pixel) {
            /// Returns whether a pixel was erased or not
            pixels.remove(pixel)
            return true
        } else {
            pixels.insert(pixel)
            return false
        }
    }
    
    public func render() {
        DispatchQueue.main.async {
            self.view.setNeedsDisplay(self.view.frame)
        }
    }
    
    public func clear() {
        pixels = Set()
    }
    
    fileprivate func transformCoordinates(x: Int, y: Int) -> CGPoint {
        let xCor = CGFloat(x) * pixelDimension
        let yCor = CGFloat(Self.height - y - 1) * pixelDimension
        return CGPoint(x: xCor, y: yCor)
    }
    
}

public class RendererView: NSView {

    private unowned let renderer: Renderer

    public init(renderer: Renderer) {
        self.renderer = renderer
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current else {
            return
        }

        context.cgContext.setFillColor(NSColor.black.cgColor)
        context.cgContext.fill(dirtyRect)

        var rects: [CGRect] = []
        let pixels = renderer.pixels
        for pixel in pixels {
            let rect = CGRect(
                origin: renderer.transformCoordinates(x: pixel.x, y: pixel.y),
                size: CGSize(width: renderer.pixelDimension, height: renderer.pixelDimension))
            rects.append(rect)
        }
        context.cgContext.setFillColor(NSColor.white.cgColor)
        context.cgContext.fill(rects)
    }

}
