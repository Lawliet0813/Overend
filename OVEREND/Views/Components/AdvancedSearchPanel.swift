//
//  AdvancedSearchPanel.swift
//  OVEREND
//
//  進階搜尋面板 - 多條件篩選 UI
//

import SwiftUI

/// 進階搜尋面板
struct AdvancedSearchPanel: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var filter: AdvancedSearchFilter
    var onApply: () -> Void
    var onReset: () -> Void
    
    @State private var yearFromText: String = ""
    @State private var yearToText: String = ""
    @State private var showTypePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Text("進階搜尋")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if filter.hasFilters {
                    Button("重置") {
                        filter.reset()
                        yearFromText = ""
                        yearToText = ""
                        onReset()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(theme.destructive)
                }
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - 文字搜尋
                    filterSection(title: "文字搜尋", icon: "magnifyingglass") {
                        TextField("搜尋標題、作者、摘要...", text: $filter.textQuery)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("搜尋範圍", selection: $filter.searchScope) {
                            ForEach(AdvancedSearchFilter.SearchScope.allCases, id: \.self) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // MARK: - 年份範圍
                    filterSection(title: "年份範圍", icon: "calendar") {
                        HStack(spacing: 12) {
                            TextField("起始年份", text: $yearFromText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: yearFromText) { _, newValue in
                                    filter.yearFrom = Int(newValue)
                                }
                            
                            Text("至")
                                .foregroundColor(theme.textMuted)
                            
                            TextField("結束年份", text: $yearToText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: yearToText) { _, newValue in
                                    filter.yearTo = Int(newValue)
                                }
                        }
                        
                        // 快捷按鈕
                        HStack(spacing: 8) {
                            quickYearButton("近 5 年") {
                                let currentYear = Calendar.current.component(.year, from: Date())
                                yearFromText = "\(currentYear - 5)"
                                yearToText = "\(currentYear)"
                                filter.yearFrom = currentYear - 5
                                filter.yearTo = currentYear
                            }
                            quickYearButton("近 10 年") {
                                let currentYear = Calendar.current.component(.year, from: Date())
                                yearFromText = "\(currentYear - 10)"
                                yearToText = "\(currentYear)"
                                filter.yearFrom = currentYear - 10
                                filter.yearTo = currentYear
                            }
                            quickYearButton("本年度") {
                                let currentYear = Calendar.current.component(.year, from: Date())
                                yearFromText = "\(currentYear)"
                                yearToText = "\(currentYear)"
                                filter.yearFrom = currentYear
                                filter.yearTo = currentYear
                            }
                        }
                    }
                    
                    // MARK: - 書目類型
                    filterSection(title: "書目類型", icon: "doc.text") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(Constants.BibTeX.supportedTypes, id: \.self) { type in
                                typeToggle(type)
                            }
                        }
                    }
                    
                    // MARK: - 附件狀態
                    filterSection(title: "附件狀態", icon: "paperclip") {
                        HStack(spacing: 16) {
                            triStateToggle("PDF", value: $filter.hasPDF)
                            triStateToggle("DOI", value: $filter.hasDOI)
                            triStateToggle("URL", value: $filter.hasURL)
                        }
                    }
                    
                    // MARK: - 標記狀態
                    filterSection(title: "標記狀態", icon: "star") {
                        triStateToggle("已標星", value: $filter.isStarred)
                    }
                }
                .padding(.bottom, 16)
            }
            
            Divider()
            
            // MARK: - 操作按鈕
            HStack {
                // 篩選條件摘要
                if filter.hasFilters {
                    Text(filter.filterSummary)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("套用篩選") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            }
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .background(theme.card)
        .onAppear {
            // 初始化年份欄位
            if let from = filter.yearFrom {
                yearFromText = "\(from)"
            }
            if let to = filter.yearTo {
                yearToText = "\(to)"
            }
        }
    }
    
    // MARK: - 輔助視圖
    
    /// 篩選區塊
    private func filterSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            content()
        }
    }
    
    /// 快捷年份按鈕
    private func quickYearButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label) {
            action()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(theme.accentLight)
        .foregroundColor(theme.accent)
        .cornerRadius(6)
        .buttonStyle(.plain)
    }
    
    /// 書目類型切換
    private func typeToggle(_ type: String) -> some View {
        let isSelected = filter.entryTypes.contains(type)
        let displayName = Constants.BibTeX.displayName(for: type)
        
        return Button {
            if isSelected {
                filter.entryTypes.remove(type)
            } else {
                filter.entryTypes.insert(type)
            }
        } label: {
            Text(displayName)
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(isSelected ? theme.accent : theme.tableRowHover)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    /// 三態切換（有/無/不限）
    private func triStateToggle(_ label: String, value: Binding<Bool?>) -> some View {
        Menu {
            Button("不限") { value.wrappedValue = nil }
            Button("有 \(label)") { value.wrappedValue = true }
            Button("無 \(label)") { value.wrappedValue = false }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12))
                
                Text(triStateLabel(value.wrappedValue))
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(triStateColor(value.wrappedValue))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.tableRowHover)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func triStateLabel(_ value: Bool?) -> String {
        switch value {
        case true: return "有"
        case false: return "無"
        case nil: return "不限"
        }
    }
    
    private func triStateColor(_ value: Bool?) -> Color {
        switch value {
        case true: return .green
        case false: return .red
        case nil: return .gray
        }
    }
}

// MARK: - 預覽

#Preview {
    AdvancedSearchPanel(
        filter: .constant(AdvancedSearchFilter()),
        onApply: {},
        onReset: {}
    )
    .environmentObject(AppTheme())
}
