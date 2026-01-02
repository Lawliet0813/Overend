//
//  FocusWritingView.swift
//  OVEREND
//
//  專注模式 - 全螢幕無干擾寫作體驗
//

import SwiftUI
import AppKit

/// 專注模式背景主題
enum FocusBackgroundTheme: String, CaseIterable, Identifiable {
    case white = "white"
    case sepia = "sepia"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .white: return "白色"
        case .sepia: return "米色"
        case .dark: return "深色"
        }
    }
    
    var icon: String {
        switch self {
        case .white: return "sun.max"
        case .sepia: return "leaf"
        case .dark: return "moon"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .white: return Color(white: 0.98)
        case .sepia: return Color(red: 0.96, green: 0.94, blue: 0.88)
        case .dark: return Color(red: 0.12, green: 0.12, blue: 0.14)
        }
    }
    
    var textColor: Color {
        switch self {
        case .white, .sepia: return Color(white: 0.15)
        case .dark: return Color(white: 0.85)
        }
    }
    
    var toolbarColor: Color {
        switch self {
        case .white: return Color(white: 0.95)
        case .sepia: return Color(red: 0.93, green: 0.91, blue: 0.85)
        case .dark: return Color(red: 0.18, green: 0.18, blue: 0.20)
        }
    }
}

/// 專注模式視圖
struct FocusWritingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AppTheme
    
    @ObservedObject var document: Document
    
    // MARK: - 狀態
    @State private var backgroundTheme: FocusBackgroundTheme = .white
    @State private var showToolbar = true
    @State private var toolbarOpacity: Double = 1.0
    @State private var hideToolbarTimer: Timer?
    @State private var textContent: String = ""
    @State private var wordCount: Int = 0
    @State private var characterCount: Int = 0
    @State private var isSaving = false
    @State private var lastSaved: Date?
    
    // 編輯器設定
    @State private var fontSize: CGFloat = 18
    @State private var lineSpacing: CGFloat = 1.8
    @State private var maxWidth: CGFloat = 680
    
    var body: some View {
        ZStack {
            // 背景
            backgroundTheme.backgroundColor
                .ignoresSafeArea()
            
            // 主內容
            VStack(spacing: 0) {
                // 浮動工具列
                if showToolbar {
                    focusToolbar
                        .opacity(toolbarOpacity)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 編輯區域
                ScrollView {
                    VStack {
                        Spacer(minLength: 80)
                        
                        // 文字編輯器
                        FocusTextEditor(
                            text: $textContent,
                            fontSize: fontSize,
                            lineSpacing: lineSpacing,
                            textColor: backgroundTheme.textColor
                        )
                        .frame(maxWidth: maxWidth)
                        .onChange(of: textContent) { _, newValue in
                            updateStats()
                            scheduleAutoSave()
                        }
                        
                        Spacer(minLength: 200)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 底部狀態列
                bottomStatusBar
            }
        }
        .onAppear {
            loadContent()
            startToolbarAutoHide()
        }
        .onDisappear {
            saveContent()
            hideToolbarTimer?.invalidate()
        }
        .onHover { hovering in
            if hovering {
                showToolbarTemporarily()
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    showToolbarTemporarily()
                }
        )
    }
    
    // MARK: - 工具列
    
    private var focusToolbar: some View {
        HStack(spacing: 16) {
            // 退出按鈕
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                    Text("退出專注模式")
                        .font(.system(size: 14))
                }
                .foregroundColor(backgroundTheme.textColor.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(backgroundTheme.toolbarColor)
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape)
            
            Spacer()
            
            // 主題切換
            HStack(spacing: 4) {
                ForEach(FocusBackgroundTheme.allCases) { themeOption in
                    Button(action: {
                        withAnimation(AnimationSystem.Easing.standard) {
                            backgroundTheme = themeOption
                        }
                    }) {
                        Image(systemName: themeOption.icon)
                            .font(.system(size: 14))
                            .foregroundColor(
                                backgroundTheme == themeOption
                                    ? theme.accent
                                    : backgroundTheme.textColor.opacity(0.5)
                            )
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(backgroundTheme == themeOption
                                        ? theme.accentLight.opacity(0.5)
                                        : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(themeOption.displayName)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(backgroundTheme.toolbarColor)
            )
            
            // 字體大小
            HStack(spacing: 8) {
                Button(action: { fontSize = max(14, fontSize - 2) }) {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                
                Text("\(Int(fontSize))")
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 24)
                
                Button(action: { fontSize = min(28, fontSize + 2) }) {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(backgroundTheme.textColor.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(backgroundTheme.toolbarColor)
            )
            
            Spacer()
            
            // 儲存狀態
            HStack(spacing: 6) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("儲存中...")
                } else if let saved = lastSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已儲存於 \(formatTime(saved))")
                }
            }
            .font(.system(size: 13))
            .foregroundColor(backgroundTheme.textColor.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            backgroundTheme.toolbarColor.opacity(0.95)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
    
    // MARK: - 底部狀態列
    
    private var bottomStatusBar: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // 字數
            HStack(spacing: 4) {
                Image(systemName: "textformat.abc")
                    .font(.system(size: 12))
                Text("\(wordCount) 字")
            }
            
            // 字元數
            HStack(spacing: 4) {
                Image(systemName: "character")
                    .font(.system(size: 12))
                Text("\(characterCount) 字元")
            }
            
            // 預估頁數
            HStack(spacing: 4) {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 12))
                Text("~\(max(1, wordCount / 300)) 頁")
            }
            
            Spacer()
        }
        .font(.system(size: 13))
        .foregroundColor(backgroundTheme.textColor.opacity(0.4))
        .padding(.vertical, 8)
        .background(backgroundTheme.toolbarColor.opacity(0.5))
    }
    
    // MARK: - 輔助方法
    
    private func loadContent() {
        // 從 document 載入內容
        if let rtfData = document.rtfData {
            do {
                let attrString = try NSAttributedString(
                    data: rtfData,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                textContent = attrString.string
            } catch {
                textContent = ""
            }
        }
        updateStats()
    }
    
    private func saveContent() {
        isSaving = true
        
        // 轉換為 RTF 並儲存
        let attrString = NSAttributedString(string: textContent)
        do {
            let rtfData = try attrString.data(
                from: NSRange(location: 0, length: attrString.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            document.rtfData = rtfData
            document.updatedAt = Date()
            lastSaved = Date()
        } catch {
            print("❌ 儲存失敗：\(error)")
        }
        
        isSaving = false
    }
    
    private func updateStats() {
        // 計算字數（中文按字計算）
        let cleanText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 中文字數
        let chineseCount = cleanText.filter { $0.unicodeScalars.allSatisfy { $0.value >= 0x4E00 && $0.value <= 0x9FFF } }.count
        
        // 英文單詞數
        let englishWords = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.rangeOfCharacter(from: CharacterSet.letters) != nil }
            .filter { !$0.unicodeScalars.allSatisfy { $0.value >= 0x4E00 && $0.value <= 0x9FFF } }
            .count
        
        wordCount = chineseCount + englishWords
        characterCount = cleanText.count
    }
    
    private func scheduleAutoSave() {
        // 簡單的自動儲存邏輯
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            saveContent()
        }
    }
    
    private func showToolbarTemporarily() {
        withAnimation(AnimationSystem.Panel.fadeIn) {
            showToolbar = true
            toolbarOpacity = 1.0
        }
        startToolbarAutoHide()
    }
    
    private func startToolbarAutoHide() {
        hideToolbarTimer?.invalidate()
        hideToolbarTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(AnimationSystem.Panel.fadeOut) {
                toolbarOpacity = 0.3
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 專注模式文字編輯器

struct FocusTextEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let textColor: Color
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 20)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // 更新字體和顏色
        let font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineSpacing
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(textColor),
            .paragraphStyle: paragraphStyle
        ]
        
        textView.typingAttributes = attributes
        
        // 只在外部變更時更新文字
        if textView.string != text && !context.coordinator.isUpdating {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FocusTextEditor
        var isUpdating = false
        
        init(_ parent: FocusTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            isUpdating = false
        }
    }
}

// MARK: - 預覽

#Preview {
    FocusWritingView(document: Document())
        .environmentObject(AppTheme())
}
