//
//  KeyBindingsSection.swift
//  OVEREND
//
//  快捷鍵設定區塊
//

import SwiftUI

struct KeyBindingsSection: View {
    @EnvironmentObject var theme: AppTheme
    
    private let shortcuts: [(action: String, keys: [String])] = [
        ("快速引用", ["⌘", "E"]),
        ("AI 改寫", ["⌘", "J"]),
        ("專注模式", ["F11"]),
        ("粗體", ["⌘", "B"]),
        ("斜體", ["⌘", "I"]),
        ("儲存文件", ["⌘", "S"])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "keyboard", title: "快捷鍵")
            
            VStack(spacing: 0) {
                // 表頭
                HStack {
                    Text("動作")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("快捷鍵")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                
                // 快捷鍵列表
                ForEach(shortcuts, id: \.action) { shortcut in
                    ShortcutRow(action: shortcut.action, keys: shortcut.keys)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

// MARK: - 快捷鍵行

struct ShortcutRow: View {
    let action: String
    let keys: [String]
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Text(action)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(keys.indices, id: \.self) { index in
                    KeyboardKey(key: keys[index])
                    
                    if index < keys.count - 1 {
                        Text("+")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isHovered ? Color.white.opacity(0.05) : .clear)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 鍵盤按鍵樣式

struct KeyboardKey: View {
    let key: String
    
    var body: some View {
        Text(key)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#e5e7eb"))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "#4b5563"), lineWidth: 1)
            )
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
    }
}

#Preview {
    KeyBindingsSection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
