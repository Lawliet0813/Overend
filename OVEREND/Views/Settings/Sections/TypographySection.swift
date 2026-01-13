//
//  TypographySection.swift
//  OVEREND
//
//  字型設定區塊
//

import SwiftUI

struct TypographySection: View {
    @EnvironmentObject var theme: AppTheme
    @State private var selectedFont = "Playfair Display"
    @State private var fontSize = "16px"
    
    private let fontFamilies = ["Space Grotesk", "Inter", "Playfair Display", "Roboto Mono"]
    private let fontSizes = ["14px", "16px", "18px"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "textformat", title: "字型設定")
            
            VStack(spacing: 16) {
                // 選擇器
                HStack(spacing: 16) {
                    // 字型家族
                    VStack(alignment: .leading, spacing: 6) {
                        Text("字型")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Picker("", selection: $selectedFont) {
                            ForEach(fontFamilies, id: \.self) { font in
                                Text(font).tag(font)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#1A2C24"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .cornerRadius(4)
                    }
                    
                    // 字體大小
                    VStack(alignment: .leading, spacing: 6) {
                        Text("字級")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Picker("", selection: $fontSize) {
                            ForEach(fontSizes, id: \.self) { size in
                                Text(size).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#1A2C24"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .cornerRadius(4)
                    }
                }
                
                // 預覽區域
                VStack(alignment: .leading, spacing: 8) {
                    Text("量子運算時代的來臨")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#10221a"))
                    
                    Text("傳統電腦依賴於存在於 0 或 1 狀態的位元，而量子電腦則利用量子位元。這些量子位元可以處於疊加狀態，從而在密碼學和藥物發現等特定領域實現指數級更快的計算 ")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#10221a").opacity(0.8))
                    + Text("[1]")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.emerald)
                        .baselineOffset(4)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#f5f8f7"))
                .cornerRadius(8)
            }
            .padding(20)
            .background(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    TypographySection()
        .padding(32)
        .background(Color(hex: "#10221a"))
        .environmentObject(AppTheme())
}
