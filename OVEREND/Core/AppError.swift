//
//  AppError.swift
//  OVEREND
//
//  應用層統一錯誤處理協議與實現
//

import Foundation

// MARK: - 應用錯誤協議

/// 應用層統一錯誤協議
protocol AppError: Error, LocalizedError {
    /// 錯誤代碼
    var code: String { get }

    /// 用戶友好的錯誤描述
    var userMessage: String { get }

    /// 技術細節（用於日誌）
    var technicalDetails: String? { get }

    /// 錯誤類別
    var category: ErrorCategory { get }
}

// MARK: - 錯誤類別

/// 錯誤類別枚舉
enum ErrorCategory: String {
    case network        // 網路錯誤
    case persistence    // 資料持久化錯誤
    case validation     // 驗證錯誤
    case authentication // 認證錯誤
    case authorization  // 授權錯誤
    case fileSystem     // 文件系統錯誤
    case parsing        // 解析錯誤
    case business       // 業務邏輯錯誤
    case unknown        // 未知錯誤
}

// MARK: - 通用應用錯誤

/// 通用應用錯誤實現
struct GenericAppError: AppError {
    let code: String
    let userMessage: String
    let technicalDetails: String?
    let category: ErrorCategory

    var errorDescription: String? {
        userMessage
    }

    var failureReason: String? {
        technicalDetails
    }

    init(
        code: String,
        userMessage: String,
        technicalDetails: String? = nil,
        category: ErrorCategory = .unknown
    ) {
        self.code = code
        self.userMessage = userMessage
        self.technicalDetails = technicalDetails
        self.category = category
    }
}

// MARK: - 常見錯誤快捷方式

extension AppError {
    /// 網路錯誤
    static func network(
        code: String = "ERR_NETWORK",
        message: String = "網路連線失敗"
    ) -> GenericAppError {
        GenericAppError(
            code: code,
            userMessage: message,
            category: .network
        )
    }

    /// 資料庫錯誤
    static func persistence(
        code: String = "ERR_DB",
        message: String = "資料保存失敗"
    ) -> GenericAppError {
        GenericAppError(
            code: code,
            userMessage: message,
            category: .persistence
        )
    }

    /// 驗證錯誤
    static func validation(
        code: String = "ERR_VALIDATION",
        message: String = "輸入資料無效"
    ) -> GenericAppError {
        GenericAppError(
            code: code,
            userMessage: message,
            category: .validation
        )
    }

    /// 文件系統錯誤
    static func fileSystem(
        code: String = "ERR_FILE",
        message: String = "文件操作失敗"
    ) -> GenericAppError {
        GenericAppError(
            code: code,
            userMessage: message,
            category: .fileSystem
        )
    }

    /// 解析錯誤
    static func parsing(
        code: String = "ERR_PARSE",
        message: String = "資料解析失敗"
    ) -> GenericAppError {
        GenericAppError(
            code: code,
            userMessage: message,
            category: .parsing
        )
    }
}

// MARK: - 錯誤日誌記錄器

/// 錯誤日誌記錄器
class ErrorLogger {
    static let shared = ErrorLogger()

    private init() {}

    /// 記錄錯誤
    func log(_ error: Error, context: String? = nil) {
        if let appError = error as? AppError {
            #if DEBUG
            print("[\(appError.category.rawValue.uppercased())] [\(appError.code)] \(appError.userMessage)")
            #endif
            if let details = appError.technicalDetails {
                #if DEBUG
                print("  詳細: \(details)")
                #endif
            }
            if let context = context {
                #if DEBUG
                print("  上下文: \(context)")
                #endif
            }
        } else {
            #if DEBUG
            print("[ERROR] \(error.localizedDescription)")
            #endif
            if let context = context {
                #if DEBUG
                print("  上下文: \(context)")
                #endif
            }
        }
    }

    /// 記錄錯誤並顯示 Toast
    func logAndShow(_ error: Error, context: String? = nil) {
        log(error, context: context)

        let message = (error as? AppError)?.userMessage ?? error.localizedDescription
        DispatchQueue.main.async {
            ToastManager.shared.showError(message)
        }
    }
}
