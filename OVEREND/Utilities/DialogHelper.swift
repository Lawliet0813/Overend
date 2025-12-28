//
//  DialogHelper.swift
//  OVEREND
//
//  AppKit 對話框輔助工具
//

import Foundation
#if canImport(AppKit)
import AppKit

class DialogHelper {

    /// 顯示文字輸入對話框
    /// - Parameters:
    ///   - title: 對話框標題
    ///   - message: 提示訊息
    ///   - defaultValue: 預設值
    ///   - placeholder: 佔位符文字
    ///   - okButtonTitle: 確定按鈕文字
    ///   - cancelButtonTitle: 取消按鈕文字
    /// - Returns: 用戶輸入的文字，如果取消則返回 nil
    static func showTextInputDialog(
        title: String,
        message: String,
        defaultValue: String = "",
        placeholder: String = "",
        okButtonTitle: String = "確定",
        cancelButtonTitle: String = "取消"
    ) -> String? {
        // 必須在主線程上同步執行
        guard Thread.isMainThread else {
            var result: String? = nil
            DispatchQueue.main.sync {
                result = showTextInputDialog(
                    title: title,
                    message: message,
                    defaultValue: defaultValue,
                    placeholder: placeholder,
                    okButtonTitle: okButtonTitle,
                    cancelButtonTitle: cancelButtonTitle
                )
            }
            return result
        }

        // 在主線程上直接執行
        var result: String? = nil
        let dialog = TextInputDialog()
        dialog.show(
            title: title,
            message: message,
            defaultValue: defaultValue,
            placeholder: placeholder,
            okButtonTitle: okButtonTitle,
            cancelButtonTitle: cancelButtonTitle
        ) { value in
            result = value
        }

        return result
    }

    /// 顯示確認對話框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - confirmButtonTitle: 確認按鈕文字
    ///   - cancelButtonTitle: 取消按鈕文字
    ///   - style: 對話框樣式
    /// - Returns: 是否確認
    static func showConfirmDialog(
        title: String,
        message: String,
        confirmButtonTitle: String = "確定",
        cancelButtonTitle: String = "取消",
        style: NSAlert.Style = .warning
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: confirmButtonTitle)
        alert.addButton(withTitle: cancelButtonTitle)

        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }

    /// 顯示錯誤對話框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 錯誤訊息
    static func showErrorDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }

    /// 顯示訊息對話框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    static func showInfoDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}

#endif
