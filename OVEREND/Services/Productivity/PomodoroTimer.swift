//
//  PomodoroTimer.swift
//  OVEREND
//
//  番茄鐘計時器 - 專注寫作時間管理
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

/// 番茄鐘狀態
enum PomodoroState: String {
    case idle = "準備開始"
    case working = "專注中"
    case shortBreak = "短休息"
    case longBreak = "長休息"
    case paused = "已暫停"
}

/// 番茄鐘計時器
@MainActor
class PomodoroTimer: ObservableObject {
    
    static let shared = PomodoroTimer()
    
    // MARK: - 設定
    @Published var workDuration: TimeInterval = 25 * 60  // 25 分鐘
    @Published var shortBreakDuration: TimeInterval = 5 * 60  // 5 分鐘
    @Published var longBreakDuration: TimeInterval = 15 * 60  // 15 分鐘
    @Published var sessionsBeforeLongBreak: Int = 4
    
    // MARK: - 狀態
    @Published private(set) var state: PomodoroState = .idle
    @Published private(set) var timeRemaining: TimeInterval = 25 * 60
    @Published private(set) var completedSessions: Int = 0
    @Published private(set) var totalFocusTime: TimeInterval = 0
    
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var pausedTimeRemaining: TimeInterval?
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - 計算屬性
    
    /// 格式化的剩餘時間
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 進度百分比 (0.0 - 1.0)
    var progress: Double {
        let total: TimeInterval
        switch state {
        case .working:
            total = workDuration
        case .shortBreak:
            total = shortBreakDuration
        case .longBreak:
            total = longBreakDuration
        default:
            return 0
        }
        return 1.0 - (timeRemaining / total)
    }
    
    /// 今日專注時間格式化
    var formattedTotalFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = (Int(totalFocusTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    // MARK: - 控制方法
    
    /// 開始專注
    func startWork() {
        state = .working
        timeRemaining = workDuration
        sessionStartTime = Date()
        startTimer()
        
        // 播放開始音效
        NSSound(named: "Tink")?.play()
    }
    
    /// 開始休息
    func startBreak() {
        let isLongBreak = (completedSessions % sessionsBeforeLongBreak == 0) && completedSessions > 0
        
        if isLongBreak {
            state = .longBreak
            timeRemaining = longBreakDuration
        } else {
            state = .shortBreak
            timeRemaining = shortBreakDuration
        }
        
        startTimer()
    }
    
    /// 暫停
    func pause() {
        guard state == .working || state == .shortBreak || state == .longBreak else { return }
        
        pausedTimeRemaining = timeRemaining
        timer?.invalidate()
        timer = nil
        
        // 記錄已專注時間
        if state == .working, let startTime = sessionStartTime {
            totalFocusTime += Date().timeIntervalSince(startTime)
        }
        
        state = .paused
    }
    
    /// 繼續
    func resume() {
        guard state == .paused, let remaining = pausedTimeRemaining else { return }
        
        timeRemaining = remaining
        state = .working
        sessionStartTime = Date()
        startTimer()
    }
    
    /// 停止/重置
    func stop() {
        timer?.invalidate()
        timer = nil
        
        // 記錄已專注時間
        if state == .working, let startTime = sessionStartTime {
            totalFocusTime += Date().timeIntervalSince(startTime)
        }
        
        state = .idle
        timeRemaining = workDuration
        pausedTimeRemaining = nil
        sessionStartTime = nil
    }
    
    /// 跳過休息
    func skipBreak() {
        guard state == .shortBreak || state == .longBreak else { return }
        timer?.invalidate()
        timer = nil
        startWork()
    }
    
    // MARK: - 私有方法
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            timerCompleted()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        
        switch state {
        case .working:
            // 完成一個番茄鐘
            completedSessions += 1
            if let startTime = sessionStartTime {
                totalFocusTime += Date().timeIntervalSince(startTime)
            }
            
            sendNotification(title: "🍅 太棒了！", body: "完成一個番茄鐘，休息一下吧")
            NSSound(named: "Glass")?.play()
            
            // 自動開始休息
            startBreak()
            
        case .shortBreak, .longBreak:
            sendNotification(title: "⏰ 休息結束", body: "準備好繼續專注了嗎？")
            NSSound(named: "Basso")?.play()
            
            state = .idle
            timeRemaining = workDuration
            
        default:
            break
        }
    }
    
    // MARK: - 通知
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
