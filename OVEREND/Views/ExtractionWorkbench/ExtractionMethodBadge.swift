//
//  ExtractionMethodBadge.swift
//  OVEREND
//
//  提取方法標籤元件
//

import SwiftUI

/// 顯示提取方法的標籤
struct ExtractionMethodBadge: View {
    let method: String?
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 12))
            
            Text(displayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
    }
    
    private var displayName: String {
        switch method {
        case "apple_ai": return "Apple Intelligence"
        case "doi": return "DOI Lookup"
        case "regex": return "Regex"
        case "pdf_attributes": return "PDF Metadata"
        case "filename": return "Filename"
        default: return method ?? "Unknown"
        }
    }
    
    private var iconName: String {
        switch method {
        case "apple_ai": return "brain.head.profile"
        case "doi": return "link"
        case "regex": return "textformat.abc"
        case "pdf_attributes": return "doc.text"
        case "filename": return "doc"
        default: return "questionmark.circle"
        }
    }
    
    private var textColor: Color {
        switch method {
        case "apple_ai": return Color(hex: "#9333EA")  // 紫色
        case "doi": return Color(hex: "#2563EB")       // 藍色
        case "regex": return Color(hex: "#EA580C")     // 橙色
        case "pdf_attributes": return Color(hex: "#0891B2")  // 青色
        case "filename": return theme.textMuted
        default: return theme.textMuted
        }
    }
    
    private var backgroundColor: Color {
        textColor.opacity(0.1)
    }
}

#Preview {
    VStack(spacing: 12) {
        ExtractionMethodBadge(method: "apple_ai")
        ExtractionMethodBadge(method: "doi")
        ExtractionMethodBadge(method: "regex")
        ExtractionMethodBadge(method: "pdf_attributes")
        ExtractionMethodBadge(method: "filename")
        ExtractionMethodBadge(method: nil)
    }
    .padding()
    .environmentObject(AppTheme())
}
