import SwiftUI
import AppKit

struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 17)
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        
        // TextKit 2 Setup
        // Using the constructor that enables TextKit 2 by default in macOS 12+
        let textContentStorage = NSTextContentStorage()
        let textLayoutManager = NSTextLayoutManager()
        textContentStorage.addTextLayoutManager(textLayoutManager)
        
        let textContainer = NSTextContainer(size: NSSize(width: 0, height: 0))
        textContainer.widthTracksTextView = true
        textLayoutManager.textContainer = textContainer
        
        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.font = font
        textView.isRichText = false // Plain text for Markdown
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        
        // Typography Optimization for CJK
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.6 // 1.6x Line Height
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.labelColor
        ]
        
        scrollView.documentView = textView
        
        // Initial Text
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        
        init(_ parent: MacEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
    }
}
