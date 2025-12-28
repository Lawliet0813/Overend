//
//  TextInputDialog.swift
//  OVEREND
//
//  自定義文字輸入對話框（使用 NSPanel）
//

import Foundation
#if canImport(AppKit)
import AppKit

class TextInputDialog: NSObject, NSTextFieldDelegate {

    private var panel: NSPanel?
    private var textField: NSTextField?
    private var okButton: NSButton?
    private var completion: ((String?) -> Void)?

    func show(
        title: String,
        message: String,
        defaultValue: String = "",
        placeholder: String = "",
        okButtonTitle: String = "確定",
        cancelButtonTitle: String = "取消",
        completion: @escaping (String?) -> Void
    ) {
        self.completion = completion

        // 創建主視圖
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))

        // 標題標籤
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.frame = NSRect(x: 20, y: 110, width: 360, height: 20)
        contentView.addSubview(titleLabel)

        // 訊息標籤
        let messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = .systemFont(ofSize: 11)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.frame = NSRect(x: 20, y: 85, width: 360, height: 20)
        contentView.addSubview(messageLabel)

        // 文字輸入框
        let textField = NSTextField(frame: NSRect(x: 20, y: 50, width: 360, height: 24))
        textField.stringValue = defaultValue
        textField.placeholderString = placeholder
        textField.font = .systemFont(ofSize: 13)
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.target = self
        textField.action = #selector(textFieldAction(_:))
        textField.delegate = self
        self.textField = textField
        contentView.addSubview(textField)

        // 按鈕容器
        let buttonContainer = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 40))

        // 取消按鈕
        let cancelButton = NSButton(frame: NSRect(x: 220, y: 8, width: 80, height: 24))
        cancelButton.title = cancelButtonTitle
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction(_:))
        cancelButton.keyEquivalent = "\u{1b}" // Escape
        buttonContainer.addSubview(cancelButton)

        // 確定按鈕
        let okButton = NSButton(frame: NSRect(x: 310, y: 8, width: 80, height: 24))
        okButton.title = okButtonTitle
        okButton.bezelStyle = .rounded
        okButton.target = self
        okButton.action = #selector(okAction(_:))
        okButton.keyEquivalent = "\r" // Return
        okButton.isEnabled = !defaultValue.trimmingCharacters(in: .whitespaces).isEmpty
        self.okButton = okButton
        buttonContainer.addSubview(okButton)

        contentView.addSubview(buttonContainer)

        // 創建 Panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = ""
        panel.contentView = contentView
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.level = .modalPanel
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.worksWhenModal = true

        self.panel = panel

        // 激活應用程式並顯示 panel
        NSApp.activate(ignoringOtherApps: true)

        // 強制成為 key window 並設置焦點
        panel.makeKeyAndOrderFront(nil)

        // 延遲一點確保視窗完全顯示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            panel.makeKey()
            panel.makeFirstResponder(textField)
        }

        // 開始 modal session（會阻塞直到 stopModal）
        _ = NSApp.runModal(for: panel)

        // runModal 結束後清理
        panel.orderOut(nil)
    }

    @objc private func textFieldAction(_ sender: NSTextField) {
        // Enter 鍵按下時
        okAction(sender)
    }

    @objc private func okAction(_ sender: Any) {
        guard let textField = textField else { return }
        let value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        closeDialog(with: value.isEmpty ? nil : value)
    }

    @objc private func cancelAction(_ sender: Any) {
        closeDialog(with: nil)
    }

    private func closeDialog(with result: String?) {
        // 先調用 completion
        completion?(result)

        // 停止 modal（這會讓 runModal 返回）
        NSApp.stopModal()

        // 清理
        panel = nil
        textField = nil
        okButton = nil
        completion = nil
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let isEmpty = textField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
        okButton?.isEnabled = !isEmpty
    }
}

#endif
