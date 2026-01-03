//
//  KeyAwareView.swift
//  OVEREND
//
//  鍵盤事件監聽視圖
//

import SwiftUI
import AppKit

struct KeyAwareView: NSViewRepresentable {
    let onEvent: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class KeyView: NSView {
    var onEvent: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let onEvent = onEvent, onEvent(event) {
            return
        }
        super.keyDown(with: event)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let onEvent = onEvent, onEvent(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
