//
//  AppLogger.swift
//  OVEREND
//
//  統一日誌系統 - 取代直接使用 print
//  使用 os.Logger 提供結構化日誌記錄
//

import Foundation
import os.log

// MARK: - Log Categories

/// 應用程式日誌類別
enum LogCategory: String {
    case general = "general"
    case network = "network"
    case coreData = "coredata"
    case ai = "ai"
    case pdf = "pdf"
    case citation = "citation"
    case sync = "sync"
    case ui = "ui"
    case performance = "performance"
    case security = "security"
}

// MARK: - App Logger

/// 統一日誌管理器
final class AppLogger {
    
    // MARK: - Singleton
    
    static let shared = AppLogger()
    
    // MARK: - Properties
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.overend"
    private var loggers: [LogCategory: Logger] = [:]
    
    /// 是否啟用詳細日誌（僅在 DEBUG 模式）
    var isVerbose: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// 是否將日誌輸出到控制台（開發時使用）
    var consoleOutput: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Initialization
    
    private init() {
        // 預先建立所有類別的 Logger
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Logging Methods
    
    /// 獲取特定類別的 Logger
    func logger(for category: LogCategory) -> Logger {
        return loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
    }
    
    /// Debug 級別日誌
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        guard isVerbose else { return }
        
        let logger = self.logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(message)")
        
        if consoleOutput {
            print("🔍 DEBUG [\(category.rawValue)] [\(fileName):\(line)] \(message)")
        }
    }
    
    /// Info 級別日誌
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = self.logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(message)")
        
        if consoleOutput {
            print("ℹ️ INFO [\(category.rawValue)] [\(fileName):\(line)] \(message)")
        }
    }
    
    /// Notice 級別日誌
    func notice(_ message: String, category: LogCategory = .general) {
        let logger = self.logger(for: category)
        logger.notice("\(message)")
        
        if consoleOutput {
            print("📌 NOTICE [\(category.rawValue)] \(message)")
        }
    }
    
    /// Warning 級別日誌
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = self.logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        logger.warning("[\(fileName):\(line)] \(message)")
        
        if consoleOutput {
            print("⚠️ WARNING [\(category.rawValue)] [\(fileName):\(line)] \(message)")
        }
    }
    
    /// Error 級別日誌
    func error(_ message: String, category: LogCategory = .general, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = self.logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        
        if let error = error {
            logger.error("[\(fileName):\(line)] \(message) - Error: \(error.localizedDescription)")
            if consoleOutput {
                print("❌ ERROR [\(category.rawValue)] [\(fileName):\(line)] \(message) - \(error.localizedDescription)")
            }
        } else {
            logger.error("[\(fileName):\(line)] \(message)")
            if consoleOutput {
                print("❌ ERROR [\(category.rawValue)] [\(fileName):\(line)] \(message)")
            }
        }
    }
    
    /// Critical 級別日誌
    func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = self.logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        logger.critical("[\(fileName):\(line)] \(message)")
        
        if consoleOutput {
            print("🔴 CRITICAL [\(category.rawValue)] [\(fileName):\(line)] \(message)")
        }
    }
    
    // MARK: - Performance Logging
    
    /// 計時開始
    func startTiming(_ label: String, category: LogCategory = .performance) -> CFAbsoluteTime {
        let startTime = CFAbsoluteTimeGetCurrent()
        debug("⏱ Start: \(label)", category: category)
        return startTime
    }
    
    /// 計時結束
    func endTiming(_ label: String, startTime: CFAbsoluteTime, category: LogCategory = .performance) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let formattedTime = String(format: "%.3f", elapsed * 1000)
        info("⏱ End: \(label) - \(formattedTime)ms", category: category)
    }
    
    /// 自動計時區塊
    func measure<T>(_ label: String, category: LogCategory = .performance, block: () throws -> T) rethrows -> T {
        let startTime = startTiming(label, category: category)
        defer { endTiming(label, startTime: startTime, category: category) }
        return try block()
    }
    
    /// 非同步計時區塊
    func measureAsync<T>(_ label: String, category: LogCategory = .performance, block: () async throws -> T) async rethrows -> T {
        let startTime = startTiming(label, category: category)
        defer { endTiming(label, startTime: startTime, category: category) }
        return try await block()
    }
}

// MARK: - LogCategory CaseIterable

extension LogCategory: CaseIterable {}

// MARK: - Convenience Global Functions

/// 全域便捷日誌函數
func logDebug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: LogCategory = .general, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.error(message, category: category, error: error, file: file, function: function, line: line)
}
