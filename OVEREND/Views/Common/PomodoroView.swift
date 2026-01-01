//
//  PomodoroView.swift
//  OVEREND
//
//  番茄鐘視圖 - 專注計時器介面
//

import SwiftUI

/// 番茄鐘浮動面板
struct PomodoroView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timer = PomodoroTimer.shared
    
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題與設定
            HStack {
                HStack(spacing: 6) {
                    Text("🍅")
                        .font(.system(size: 16))
                    Text("番茄鐘")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                        .padding(4)
                        .background(Circle().fill(theme.itemHover))
                }
                .buttonStyle(.plain)
            }
            
            // 圓形進度與時間
            ZStack {
                // 背景圓
                Circle()
                    .stroke(theme.border, lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                // 進度圓
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        stateColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)
                
                // 時間與狀態
                VStack(spacing: 4) {
                    Text(timer.formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(timer.state.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(stateColor)
                }
            }
            
            // 控制按鈕
            HStack(spacing: 12) {
                switch timer.state {
                case .idle:
                    Button(action: { timer.startWork() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("開始專注")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.9))
                        )
                    }
                    .buttonStyle(.plain)
                    
                case .working:
                    Button(action: { timer.pause() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                            Text("暫停")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { timer.stop() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMuted)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.itemHover)
                            )
                    }
                    .buttonStyle(.plain)
                    
                case .paused:
                    Button(action: { timer.resume() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("繼續")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { timer.stop() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textMuted)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.itemHover)
                            )
                    }
                    .buttonStyle(.plain)
                    
                case .shortBreak, .longBreak:
                    Button(action: { timer.skipBreak() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                            Text("跳過休息")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 統計
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(timer.completedSessions)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Text("完成")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 2) {
                    Text(timer.formattedTotalFocusTime)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Text("專注時間")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 220)
        .background(theme.card)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showSettings) {
            PomodoroSettingsView()
                .environmentObject(theme)
        }
    }
    
    /// 狀態對應顏色
    private var stateColor: Color {
        switch timer.state {
        case .idle:
            return theme.textMuted
        case .working:
            return Color.red
        case .shortBreak:
            return Color.green
        case .longBreak:
            return Color.blue
        case .paused:
            return Color.orange
        }
    }
}

/// 番茄鐘設定
struct PomodoroSettingsView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timer = PomodoroTimer.shared
    
    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var sessions: Double = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("番茄鐘設定")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                SettingRow(label: "專注時間", value: $workMinutes, range: 15...60, unit: "分鐘")
                SettingRow(label: "短休息", value: $shortBreakMinutes, range: 3...15, unit: "分鐘")
                SettingRow(label: "長休息", value: $longBreakMinutes, range: 10...30, unit: "分鐘")
                SettingRow(label: "長休息間隔", value: $sessions, range: 2...6, unit: "個番茄")
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("儲存") {
                    timer.workDuration = workMinutes * 60
                    timer.shortBreakDuration = shortBreakMinutes * 60
                    timer.longBreakDuration = longBreakMinutes * 60
                    timer.sessionsBeforeLongBreak = Int(sessions)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onAppear {
            workMinutes = timer.workDuration / 60
            shortBreakMinutes = timer.shortBreakDuration / 60
            longBreakMinutes = timer.longBreakDuration / 60
            sessions = Double(timer.sessionsBeforeLongBreak)
        }
    }
}

struct SettingRow: View {
    @EnvironmentObject var theme: AppTheme
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Slider(value: $value, in: range, step: 1)
                    .frame(width: 100)
                
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(theme.textMuted)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }
}

/// 工具列迷你番茄鐘按鈕
struct PomodoroToolbarButton: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject private var timer = PomodoroTimer.shared
    @State private var showPomodoro = false
    
    var body: some View {
        Button(action: { showPomodoro.toggle() }) {
            HStack(spacing: 4) {
                Text("🍅")
                    .font(.system(size: 12))
                
                if timer.state == .working || timer.state == .shortBreak || timer.state == .longBreak {
                    Text(timer.formattedTime)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(timerColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(timer.state == .idle ? theme.itemHover : timerColor.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPomodoro, arrowEdge: .bottom) {
            PomodoroView()
                .environmentObject(theme)
        }
    }
    
    private var timerColor: Color {
        switch timer.state {
        case .working: return .red
        case .shortBreak, .longBreak: return .green
        case .paused: return .orange
        default: return theme.textMuted
        }
    }
}

#Preview {
    PomodoroView()
        .environmentObject(AppTheme())
        .padding()
}
