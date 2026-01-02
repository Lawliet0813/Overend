//
//  EditorListView.swift
//  OVEREND
//
//  文稿列表視圖 - 寫作中心卡片網格
//

import SwiftUI
import CoreData

/// 文稿列表視圖（寫作中心）
struct EditorListView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    @State private var showNewDocumentSheet = false
    @State private var newDocumentTitle = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 24)
    ]
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            if documents.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 標題與統計
                        headerSection

                        // 文稿網格
                        LazyVGrid(columns: columns, spacing: 24) {
                            // 新增文稿按鈕卡片
                            newDocumentCard

                            // 現有文稿卡片
                            ForEach(documents) { document in
                                DocumentCardView(document: document) {
                                    withAnimation(AnimationSystem.Easing.spring) {
                                        viewState.openDocument(document)
                                    }
                                } onDelete: {
                                    deleteDocument(document)
                                }
                                .environmentObject(theme)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.xl)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewDocumentSheet) {
            newDocumentSheet
        }
    }
    
    // MARK: - 子視圖

    /// 標題區域
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的文稿")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textPrimary)

                    Text("\(documents.count) 篇文稿")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                }

                Spacer()

                // 新增按鈕
                Button(action: { showNewDocumentSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("新增文稿")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accent)
                    )
                    .shadow(
                        color: theme.accent.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.lg)
        }
    }

    /// 新增文稿卡片
    private var newDocumentCard: some View {
        Button(action: { showNewDocumentSheet = true }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.accentLight)
                        .frame(width: 64, height: 64)

                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(theme.accent)
                }

                VStack(spacing: 4) {
                    Text("新增文稿")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    Text("開始新的寫作")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 220)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.card)

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [8, 6]
                            )
                        )
                        .foregroundColor(theme.border)
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            // 圖示
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accent)
            }

            // 文字
            VStack(spacing: 8) {
                Text("尚無文稿")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Text("創建第一份文稿開始您的學術寫作之旅")
                    .font(.system(size: 15))
                    .foregroundColor(theme.textMuted)
                    .multilineTextAlignment(.center)
            }

            // 按鈕
            Button(action: { showNewDocumentSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("新增文稿")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accent)
                )
                .shadow(
                    color: theme.accent.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var newDocumentSheet: some View {
        VStack(spacing: 24) {
            // 標題
            HStack {
                Text("新增文稿")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button(action: {
                    newDocumentTitle = ""
                    showNewDocumentSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // 輸入區域
            VStack(alignment: .leading, spacing: 12) {
                Text("文稿標題")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textMuted)

                TextField("請輸入文稿標題", text: $newDocumentTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.itemHover)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.border, lineWidth: 1)
                    )
            }

            Spacer()

            // 按鈕
            HStack(spacing: 12) {
                Button("取消") {
                    newDocumentTitle = ""
                    showNewDocumentSheet = false
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(theme.textMuted)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.itemHover)
                )

                Spacer()

                Button("建立") {
                    createDocument()
                }
                .keyboardShortcut(.return)
                .disabled(newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? theme.textMuted
                            : theme.accent
                        )
                )
            }
        }
        .padding(24)
        .frame(width: 480, height: 280)
        .background(theme.card)
    }
    
    // MARK: - 方法

    /// 建立文稿
    private func createDocument() {
        let trimmedTitle = newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let document = Document(context: viewContext, title: trimmedTitle)

        do {
            try viewContext.save()

            // 關閉表單
            newDocumentTitle = ""
            showNewDocumentSheet = false

            // 開啟新文稿
            withAnimation(AnimationSystem.Easing.spring) {
                viewState.openDocument(document)
            }

            ToastManager.shared.showSuccess("文稿「\(trimmedTitle)」已建立")
        } catch {
            print("❌ 建立文稿失敗：\(error.localizedDescription)")
            ToastManager.shared.showError("建立失敗：\(error.localizedDescription)")
        }
    }

    /// 刪除文稿
    private func deleteDocument(_ document: Document) {
        let title = document.title
        viewContext.delete(document)

        do {
            try viewContext.save()
            ToastManager.shared.showSuccess("文稿「\(title)」已刪除")
        } catch {
            print("❌ 刪除文稿失敗：\(error.localizedDescription)")
            ToastManager.shared.showError("刪除失敗")
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    let context = PersistenceController.preview.container.viewContext

    // 建立測試資料
    for i in 1...6 {
        let doc = Document(context: context, title: "測試文稿 \(i)")
        doc.updatedAt = Date().addingTimeInterval(Double(-i * 3600))
    }

    return EditorListView()
        .environmentObject(theme)
        .environmentObject(viewState)
        .environment(\.managedObjectContext, context)
        .frame(width: 1200, height: 800)
}
