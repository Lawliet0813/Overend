//
//  RichTextEditor.swift
//  OVEREND
//
//  富文本編輯器元件 - 從 DocumentEditorView 拆分
//

import SwiftUI
import AppKit

// MARK: - 富文本編輯器（A4 紙張模擬）

struct RichTextEditorView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?
    @EnvironmentObject var theme: AppTheme
    let onTextChange: () -> Void
    
    // A4 尺寸 (72 DPI: 595 x 842 pt)
    static let a4Width: CGFloat = 595
    static let a4Margin: CGFloat = 72  // 1 inch margin
    
    func makeNSView(context: Context) -> NSScrollView {
        // 創建容器 ScrollView
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        scrollView.drawsBackground = true
        
        // 創建 A4 紙張容器
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // 創建 TextView
        let textContainer = NSTextContainer(size: NSSize(
            width: Self.a4Width - (Self.a4Margin * 2),
            height: .greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        let textView = NSTextView(frame: NSRect(
            x: Self.a4Margin,
            y: Self.a4Margin,
            width: Self.a4Width - (Self.a4Margin * 2),
            height: 842 - (Self.a4Margin * 2)
        ), textContainer: textContainer)

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = []
        textView.maxSize = NSSize(width: Self.a4Width - (Self.a4Margin * 2), height: .greatestFiniteMagnitude)
        textView.minSize = NSSize(width: Self.a4Width - (Self.a4Margin * 2), height: 842 - (Self.a4Margin * 2))
        
        // 紙張樣式 - 根據主題調整
        if theme.isPrideMode {
            textView.backgroundColor = .clear
            textView.textColor = .white
            textView.insertionPointColor = .white
        } else {
            textView.backgroundColor = .white
            textView.textColor = .black
            textView.insertionPointColor = .black
        }
        textView.font = .systemFont(ofSize: 12)
        
        // 預設輸入屬性
        textView.typingAttributes = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        
        // 紙張視圖
        let paperView = NSView(frame: NSRect(x: 0, y: 0, width: Self.a4Width, height: 842))
        paperView.wantsLayer = true
        paperView.layer?.backgroundColor = theme.isPrideMode ? NSColor.clear.cgColor : NSColor.white.cgColor
        
        if !theme.isPrideMode {
            paperView.layer?.shadowColor = NSColor.black.cgColor
            paperView.layer?.shadowOffset = CGSize(width: 0, height: -2)
            paperView.layer?.shadowRadius = 8
            paperView.layer?.shadowOpacity = 0.3
        }
        
        paperView.addSubview(textView)
        
        // 設置紙張居中的剪輯視圖
        let clipView = CenteredClipView()
        clipView.documentView = paperView
        clipView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        clipView.drawsBackground = true
        
        scrollView.contentView = clipView
        scrollView.documentView = paperView
        
        // 初始內容
        textView.textStorage?.setAttributedString(attributedText)
        
        // 儲存參考並初始化 undo/redo 狀態
        DispatchQueue.main.async {
            self.textViewRef = textView
        }

        // 監聽 undo manager 通知
        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidUndoChange,
            object: textView.undoManager,
            queue: .main
        ) { _ in
            // 觸發文字變更以更新狀態
        }

        NotificationCenter.default.addObserver(
            forName: .NSUndoManagerDidRedoChange,
            object: textView.undoManager,
            queue: .main
        ) { _ in
            // 觸發文字變更以更新狀態
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let paperView = nsView.documentView,
              let textView = paperView.subviews.first as? NSTextView else { return }

        // 只在內容真正改變時更新
        if textView.attributedString() != attributedText {
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(attributedText)
            textView.selectedRanges = selectedRanges
        }

        // 讓 textView 自動調整大小以適應內容
        if let layoutManager = textView.layoutManager,
           let textContainer = textView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let contentHeight = max(842, usedRect.height + Self.a4Margin * 2)

            // 更新紙張和 textView 的高度
            paperView.frame.size = NSSize(width: Self.a4Width, height: contentHeight)
            textView.frame = NSRect(
                x: Self.a4Margin,
                y: Self.a4Margin,
                width: Self.a4Width - (Self.a4Margin * 2),
                height: contentHeight - Self.a4Margin * 2
            )

            // 通知 scrollView 內容大小已改變
            nsView.documentView?.needsLayout = true
        }
        
        // 更新主題相關樣式
        nsView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        if let clipView = nsView.contentView as? CenteredClipView {
            clipView.backgroundColor = theme.isPrideMode ? .clear : NSColor.darkGray.withAlphaComponent(0.3)
        }
        
        if let paperView = nsView.documentView {
            paperView.layer?.backgroundColor = theme.isPrideMode ? NSColor.clear.cgColor : NSColor.white.cgColor
            if theme.isPrideMode {
                paperView.layer?.shadowOpacity = 0.0
            } else {
                paperView.layer?.shadowOpacity = 0.3
            }
        }
        
        if let textView = (nsView.documentView?.subviews.first as? NSTextView) {
            textView.backgroundColor = theme.isPrideMode ? .clear : .white
            textView.textColor = theme.isPrideMode ? .white : .black
            textView.insertionPointColor = theme.isPrideMode ? .white : .black
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
            parent.onTextChange()
        }

        // 監聽 undo/redo 狀態變化
        func undoManagerDidUndo(_ notification: Notification) {
            parent.onTextChange()
        }

        func undoManagerDidRedo(_ notification: Notification) {
            parent.onTextChange()
        }
    }
}

// MARK: - 置中 ClipView

class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        
        if let documentView = documentView {
            // 水平置中
            if documentView.frame.width < proposedBounds.width {
                rect.origin.x = (documentView.frame.width - proposedBounds.width) / 2
            }
        }
        
        return rect
    }
}
