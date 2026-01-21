//
//  ModernEntryDetailView.swift
//  OVEREND
//
//  現代化書目詳情面板 - 右側顯示詳細資訊
//  注意：UI Sections 已拆分至 ModernEntryDetailView+Sections.swift
//

import SwiftUI
import PDFKit
import Vision
import CoreData

/// 現代化書目詳情視圖
@available(macOS 13.0, *)
struct ModernEntryDetailView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject var entry: Entry
    var onClose: (() -> Void)?
    
    @State var showPDFViewer = false
    @State var selectedAttachment: Attachment?
    
    // AI 功能狀態
    @StateObject var aiService = UnifiedAIService.shared
    @State var aiSummary: String = ""
    @State var aiKeywords: [String] = []
    @State var isGeneratingSummary = false
    @State var isExtractingKeywords = false
    
    // 編輯模式狀態
    @State var isEditMode: Bool = false
    @State var editedFields: [String: String] = [:]
    @State var editedTitle: String = ""
    @State var editedEntryType: String = ""
    @State var hasUnsavedChanges: Bool = false
    @State var showUnsavedAlert: Bool = false
    @State var isExtractingMetadata: Bool = false
    
    // AI 標籤建議
    @State var showSmartTagSuggestion = false
    
    // 標籤管理
    @State var isAddingTag = false
    @State var newTagSearchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            toolbarSection
            
            // 內容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題區
                    headerSection
                    
                    Divider()
                    
                    // AI 智慧分析
                    aiSection
                    
                    Divider()

                    // 標籤管理
                    tagsSection

                    Divider()
                    
                    // 書目資訊
                    metadataSection
                    
                    Divider()
                    
                    // 引用格式
                    citationSection
                    
                    Divider()
                    
                    // PDF 附件（含預覽）
                    attachmentSection
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        // Tech Style Enhancement
        .background(theme.sidebarGlass)
        .overlay(
            Rectangle()
                .fill(theme.borderSubtle)
                .frame(width: 1),
            alignment: .leading
        )
        .background(
            // 添加微妙的背景光暈
            ZStack {
                theme.background
                if theme.isDarkMode {
                    Circle()
                        .fill(theme.accent.opacity(0.05))
                        .blur(radius: 100)
                        .offset(x: 100, y: -200)
                }
            }
        )
        .sheet(isPresented: $showPDFViewer) {
            if let attachment = selectedAttachment {
                PDFViewerSheet(attachment: attachment)
                    .environmentObject(theme)
            }
        }
        .onAppear {
            // 載入已儲存的摘要
            if let saved = entry.fields["ai_summary"] {
                aiSummary = saved
            }
            if let keywordsStr = entry.fields["ai_keywords"] {
                aiKeywords = keywordsStr.components(separatedBy: ", ")
            }
            
            // 初始化編輯欄位
            editedTitle = entry.title
            editedFields = entry.fields
        }
        .alert("未儲存的變更", isPresented: $showUnsavedAlert) {
            Button("繼續編輯", role: .cancel) { }
            Button("放棄變更", role: .destructive) {
                isEditMode = false
                hasUnsavedChanges = false
                // 重置編輯欄位
                editedTitle = entry.title
                editedFields = entry.fields
            }
        } message: {
            Text("您有尚未儲存的變更，確定要放棄嗎？")
        }
    }
    
    // MARK: - 工具列
    
    private var toolbarSection: some View {
        HStack {
            Text(isEditMode ? "編輯書目" : "書目詳情")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            if isEditMode {
                // 編輯模式：AI 提取、取消和儲存按鈕
                Button(action: { performAIExtraction() }) {
                    if isExtractingMetadata {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("AI 提取", systemImage: "sparkles")
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isExtractingMetadata)
                
                Button("取消") {
                    cancelEdit()
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textMuted)
                
                Button("儲存") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!hasUnsavedChanges)
            } else {
                // 查看模式：編輯按鈕
                Button(action: { enterEditMode() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("編輯")
                    }
                    .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textMuted)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.itemHover)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.toolbar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
}

#Preview {
    let theme = AppTheme()
    let context = PersistenceController.preview.container.viewContext
    
    let library = Library(context: context)
    library.id = UUID()
    library.name = "Test"
    
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.citationKey = "test2024"
    entry.entryType = "article"
    entry.fields = [
        "title": "測試論文標題",
        "author": "張三 and 李四",
        "year": "2024",
        "journal": "測試期刊"
    ]
    entry.bibtexRaw = "@article{test2024}"
    entry.library = library
    
    if #available(macOS 26.0, *) {
        return ModernEntryDetailView(entry: entry)
            .environmentObject(theme)
            .environment(\.managedObjectContext, context)
            .frame(width: 320, height: 600)
    } else {
        // Fallback on earlier versions
    }
}
