//
//  ToastManager.swift
//  OVEREND
//
//  Toast 提示管理器 - 全局操作回饋
//

import SwiftUI
import Combine

/// Toast 類型
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return Color(hex: "#00D97E")
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

/// Toast 項目
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Toast 管理器
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published private(set) var toasts: [ToastItem] = []
    
    // MARK: - 載入狀態
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var loadingProgress: Double? = nil  // nil = 不確定進度
    
    private init() {}
    
    /// 顯示成功提示
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(message: message, type: .success, duration: duration)
    }
    
    /// 顯示錯誤提示
    func showError(_ message: String, duration: TimeInterval = 4.0) {
        show(message: message, type: .error, duration: duration)
    }
    
    /// 顯示資訊提示
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message: message, type: .info, duration: duration)
    }
    
    /// 顯示警告提示
    func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        show(message: message, type: .warning, duration: duration)
    }
    
    /// 顯示 Toast
    private func show(message: String, type: ToastType, duration: TimeInterval) {
        let toast = ToastItem(message: message, type: type, duration: duration)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toasts.append(toast)
        }
        
        // 自動移除
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            dismiss(toast)
        }
    }
    
    /// 手動關閉 Toast
    func dismiss(_ toast: ToastItem) {
        withAnimation(.easeOut(duration: 0.2)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
    
    // MARK: - 載入狀態控制
    
    /// 開始載入（不確定進度）
    func startLoading(_ message: String) {
        isLoading = true
        loadingMessage = message
        loadingProgress = nil
    }
    
    /// 開始載入（有進度）
    func startLoading(_ message: String, progress: Double) {
        isLoading = true
        loadingMessage = message
        loadingProgress = progress
    }
    
    /// 更新載入進度
    func updateProgress(_ progress: Double, message: String? = nil) {
        loadingProgress = progress
        if let msg = message {
            loadingMessage = msg
        }
    }
    
    /// 結束載入
    func stopLoading() {
        withAnimation {
            isLoading = false
            loadingMessage = ""
            loadingProgress = nil
        }
    }
    
    /// 結束載入並顯示成功
    func finishWithSuccess(_ message: String) {
        stopLoading()
        showSuccess(message)
    }
    
    /// 結束載入並顯示錯誤
    func finishWithError(_ message: String) {
        stopLoading()
        showError(message)
    }
}

