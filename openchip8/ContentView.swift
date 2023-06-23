//
//  ContentView.swift
//  openchip8
//
//  Created by Yubo Qin on 6/22/23.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject private var renderer: Renderer
    private let emulator: Emulator

    init() {
        let renderer = Renderer()
        self.renderer = renderer
        self.emulator = Emulator(
            renderer: renderer,
            keyboard: Keyboard(),
            speaker: Speaker())
    }

    var body: some View {
        Canvas { context, size in
            renderer.pixels.forEach { pixel in
                context.fill(
                    Path(renderer.pixelToRect(pixel)),
                    with: .color(.white))
            }
        }
        .frame(width: 640, height: 320)
        .background(Color.black)
        .onAppear {
            emulator.start()
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
