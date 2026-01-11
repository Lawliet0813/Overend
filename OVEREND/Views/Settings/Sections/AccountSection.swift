//
//  AccountSection.swift
//  OVEREND
//
//  帳戶設定區塊
//

import SwiftUI

struct AccountSection: View {
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "person.circle", title: "帳戶")
            
            VStack(spacing: 16) {
                // 用戶資訊卡
                HStack(spacing: 16) {
                    // 大頭像
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.emerald, Color(hex: "#065F46")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Text("U")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.emeraldBg)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("使用者")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("user@example.com")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text("專業版")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button("編輯個人資料") {
                        // Edit profile
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
                
                // 帳戶操作
                VStack(spacing: 12) {
                    SettingsRow(
                        title: "同步設定",
                        description: "在多個裝置間同步你的偏好設定。"
                    ) {
                        Button("立即同步") {
                            // Sync
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.emerald)
                    }
                    
                    SettingsRow(
                        title: "匯出資料",
                        description: "下載所有文件和文獻庫。"
                    ) {
                        Button("匯出") {
                            // Export
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.emerald)
                    }
                    
                    SettingsRow(
                        title: "登出",
                        description: "從此裝置登出帳戶。"
                    ) {
                        Button("登出") {
                            // Sign out
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    AccountSection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
