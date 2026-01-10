//
//  Logger.swift
//  OVEREND
//
//  統一的日誌輸出工具
//  僅在 DEBUG 模式下輸出，Release 版本自動靜默
//

import Foundation
import os.log

/// 應用程式日誌管理器
enum AppLogger {
    
    // MARK: - 子系統
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.overend"
    
    // MARK: - 日誌類別
    
    static let general = Logger(subsystem: subsystem, category: "general")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let coreData = Logger(subsystem: subsystem, category: "coredata")
    static let pdf = Logger(subsystem: subsystem, category: "pdf")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    
    // MARK: - 便捷方法
    
    /// 除錯訊息（僅 DEBUG 模式）
    static func debug(_ message: String, category: Logger = general) {
        #if DEBUG
        category.debug("🔍 \(message)")
        #endif
    }
    
    /// 資訊訊息
    static func info(_ message: String, category: Logger = general) {
        #if DEBUG
        category.info("ℹ️ \(message)")
        #endif
    }
    
    /// 成功訊息
    static func success(_ message: String, category: Logger = general) {
        #if DEBUG
        category.info("✅ \(message)")
        #endif
    }
    
    /// 警告訊息
    static func warning(_ message: String, category: Logger = general) {
        #if DEBUG
        category.warning("⚠️ \(message)")
        #endif
    }
    
    /// 錯誤訊息（始終輸出）
    static func error(_ message: String, category: Logger = general) {
        category.error("❌ \(message)")
    }
    
    // MARK: - 特定領域日誌
    
    /// AI 服務日誌
    static func aiLog(_ message: String) {
        #if DEBUG
        ai.debug("🤖 \(message)")
        #endif
    }
    
    /// Core Data 日誌
    static func dataLog(_ message: String) {
        #if DEBUG
        coreData.debug("💾 \(message)")
        #endif
    }
    
    /// PDF 處理日誌
    static func pdfLog(_ message: String) {
        #if DEBUG
        pdf.debug("📄 \(message)")
        #endif
    }
    
    /// 網路請求日誌
    static func networkLog(_ message: String) {
        #if DEBUG
        network.debug("🌐 \(message)")
        #endif
    }
}

// MARK: - 全域便捷函數

/// 除錯輸出（替代 print）
func debugLog(_ message: String) {
    AppLogger.debug(message)
}
