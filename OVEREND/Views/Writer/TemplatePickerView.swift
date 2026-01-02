//
//  TemplatePickerView.swift
//  OVEREND
//
//  範本選擇器 - 新增文稿時選擇寫作範本
//

import SwiftUI

/// 範本選擇器視圖
struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AppTheme
    
    var onSelect: (WritingTemplate) -> Void
    
    // MARK: - 狀態
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var selectedTemplate: WritingTemplate? = nil
    @State private var searchText = ""
    @State private var hoveredTemplate: WritingTemplate? = nil
    
    // 範本列表
    private var templates: [WritingTemplate] {
        var allTemplates = WritingTemplate.builtInTemplates
        // TODO: 載入自訂範本
        
        // 過濾分類
        if let category = selectedCategory {
            allTemplates = allTemplates.filter { $0.category == category }
        }
        
        // 搜尋過濾
        if !searchText.isEmpty {
            allTemplates = allTemplates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return allTemplates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            header
            
            Divider()
            
            // 主內容
            HStack(spacing: 0) {
                // 左側分類
                categoryList
                    .frame(width: 180)
                
                Divider()
                
                // 右側範本網格
                templateGrid
            }
            
            Divider()
            
            // 底部按鈕
            footer
        }
        .frame(width: 700, height: 500)
        .background(theme.card)
    }
    
    // MARK: - 子視圖
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("選擇範本")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("選擇一個範本開始新文稿")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            // 搜尋框
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                
                TextField("搜尋範本...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(theme.itemHover)
            )
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 全部
            categoryRow(category: nil, title: "全部範本", icon: "square.grid.2x2")
            
            Divider()
                .padding(.vertical, 8)
            
            // 各分類
            ForEach(TemplateCategory.allCases) { category in
                categoryRow(category: category, title: category.displayName, icon: category.icon)
            }
            
            Spacer()
        }
        .padding(12)
        .background(theme.background)
    }
    
    private func categoryRow(category: TemplateCategory?, title: String, icon: String) -> some View {
        Button(action: {
            withAnimation(AnimationSystem.Easing.quick) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(selectedCategory == category ? theme.accent : theme.textMuted)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(selectedCategory == category ? theme.accent : theme.textPrimary)
                
                Spacer()
                
                // 數量
                let count = countTemplates(for: category)
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(selectedCategory == category ? theme.accentLight.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(templates) { template in
                    templateCard(template)
                }
            }
            .padding(16)
        }
    }
    
    private func templateCard(_ template: WritingTemplate) -> some View {
        Button(action: {
            selectedTemplate = template
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: [theme.accentLight, theme.accentLight.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                    
                    Image(systemName: template.category.icon)
                        .font(.system(size: 32))
                        .foregroundColor(theme.accent)
                }
                
                // 標題
                HStack {
                    Text(template.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    if selectedTemplate?.id == template.id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accent)
                    }
                }
                
                // 描述
                Text(template.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 標籤
                HStack(spacing: 6) {
                    categoryTag(template.category)
                    
                    if template.isBuiltIn {
                        Text("內建")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(theme.itemHover)
                            )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        selectedTemplate?.id == template.id ? theme.accent : theme.border,
                        lineWidth: selectedTemplate?.id == template.id ? 2 : 1
                    )
            )
            .scaleEffect(hoveredTemplate?.id == template.id ? 1.02 : 1.0)
            .animation(AnimationSystem.Card.lift, value: hoveredTemplate?.id)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredTemplate = hovering ? template : nil
        }
    }
    
    private func categoryTag(_ category: TemplateCategory) -> some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 9))
            Text(category.displayName)
                .font(.system(size: 10))
        }
        .foregroundColor(theme.accent)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(theme.accentLight.opacity(0.5))
        )
    }
    
    private var footer: some View {
        HStack {
            // 範本資訊
            if let template = selectedTemplate {
                HStack(spacing: 8) {
                    Image(systemName: template.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    Text("已選取：\(template.name)")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            // 按鈕
            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(theme.itemHover)
            )
            
            Button(action: {
                if let template = selectedTemplate {
                    onSelect(template)
                    dismiss()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                    Text("建立文稿")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(selectedTemplate != nil ? theme.accent : theme.textMuted)
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedTemplate == nil)
        }
        .padding(16)
    }
    
    // MARK: - 輔助方法
    
    private func countTemplates(for category: TemplateCategory?) -> Int {
        if let category = category {
            return WritingTemplate.builtInTemplates.filter { $0.category == category }.count
        }
        return WritingTemplate.builtInTemplates.count
    }
}

// MARK: - 預覽

#Preview {
    TemplatePickerView { template in
        print("Selected: \(template.name)")
    }
    .environmentObject(AppTheme())
}
