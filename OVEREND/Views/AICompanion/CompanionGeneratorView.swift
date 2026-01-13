//
//  CompanionGeneratorView.swift
//  OVEREND
//
//  AI 角色生成器 - 讓用戶自訂專屬 AI 助理
//

import SwiftUI
import FoundationModels

// MARK: - 角色生成器視圖

@available(macOS 26.0, *)
struct CompanionGeneratorView: View {
    
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var service = CompanionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var promptText: String = ""
    @State private var companionName: String = ""
    @State private var isGenerating: Bool = false
    @State private var generatedImages: [NSImage] = []
    @State private var selectedImageIndex: Int? = nil
    @State private var errorMessage: String? = nil
    @State private var step: GeneratorStep = .input
    
    enum GeneratorStep {
        case input      // 輸入描述
        case generating // 生成中
        case selecting  // 選擇圖片
        case naming     // 命名角色
        case complete   // 完成
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部標題
            headerView
            
            Divider()
            
            // 主要內容
            contentView
            
            Divider()
            
            // 底部按鈕
            footerView
        }
        .frame(width: 500, height: 600)
        .background(theme.background)
    }
    
    // MARK: - 頂部
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("創建專屬 AI 助理")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                
                Text(stepDescription)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
            
            // 步驟指示器
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(stepIndex >= index ? theme.accent : theme.border)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
    }
    
    private var stepDescription: String {
        switch step {
        case .input: return "步驟 1/4：描述你想要的助理形象"
        case .generating: return "步驟 2/4：正在生成角色..."
        case .selecting: return "步驟 3/4：選擇你喜歡的版本"
        case .naming: return "步驟 4/4：為你的助理命名"
        case .complete: return "完成！"
        }
    }
    
    private var stepIndex: Int {
        switch step {
        case .input: return 0
        case .generating: return 1
        case .selecting: return 2
        case .naming, .complete: return 3
        }
    }
    
    // MARK: - 主要內容
    
    @ViewBuilder
    private var contentView: some View {
        switch step {
        case .input:
            inputView
        case .generating:
            generatingView
        case .selecting:
            selectingView
        case .naming:
            namingView
        case .complete:
            completeView
        }
    }
    
    // MARK: - 輸入視圖
    
    private var inputView: some View {
        VStack(spacing: 20) {
            // 提示圖示
            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundStyle(theme.accent)
                .padding(.top, 20)
            
            Text("用自然語言描述你的 AI 助理")
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
            
            // 輸入區域
            VStack(alignment: .leading, spacing: 8) {
                Text("角色描述")
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textSecondary)
                
                TextEditor(text: $promptText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.elevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .frame(height: 120)
            }
            .padding(.horizontal)
            
            // 範例提示
            VStack(alignment: .leading, spacing: 8) {
                Text("範例：")
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(examplePrompts, id: \.self) { example in
                            Button {
                                promptText = example
                            } label: {
                                Text(example)
                                    .font(.caption)
                                    .foregroundStyle(theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(theme.elevated)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private let examplePrompts = [
        "穿著實驗袍的柴犬",
        "戴著博士帽的白貓",
        "手持鋼筆的小狐狸",
        "騎著書本的小精靈",
        "穿西裝的企鵝紳士"
    ]
    
    // MARK: - 生成中視圖
    
    private var generatingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("正在生成你的專屬助理...")
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
            
            Text("這可能需要幾秒鐘")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            
            // 動態提示
            Text(generatingTips.randomElement() ?? "")
                .font(.caption)
                .foregroundStyle(theme.accent)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private let generatingTips = [
        "💡 AI 正在發揮創意中...",
        "🎨 調配專屬色彩...",
        "✨ 添加一點魔法...",
        "🦉 正在賦予角色個性..."
    ]
    
    // MARK: - 選擇視圖
    
    private var selectingView: some View {
        VStack(spacing: 16) {
            Text("選擇你最喜歡的版本")
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
                .padding(.top)
            
            // 圖片網格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(generatedImages.indices, id: \.self) { index in
                    Button {
                        selectedImageIndex = index
                    } label: {
                        Image(nsImage: generatedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedImageIndex == index ? theme.accent : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: selectedImageIndex == index ? theme.accent.opacity(0.3) : Color.clear,
                                radius: 8
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            if generatedImages.isEmpty {
                // 模擬生成的佔位圖
                Text("（這裡會顯示 AI 生成的角色圖片）")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 命名視圖
    
    private var namingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 預覽選中的角色
            if let index = selectedImageIndex, index < generatedImages.count {
                Image(nsImage: generatedImages[index])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.accent, lineWidth: 3)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.2))
                        .frame(width: 120, height: 120)
                    Text("🦉")
                        .font(.system(size: 60))
                }
            }
            
            Text("為你的助理取個名字吧！")
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
            
            TextField("輸入名字", text: $companionName)
                .textFieldStyle(.plain)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.elevated)
                )
                .frame(width: 200)
            
            Spacer()
        }
    }
    
    // MARK: - 完成視圖
    
    private var completeView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("🎉")
                .font(.system(size: 60))
            
            Text("歡迎 \(companionName)！")
                .font(.title.bold())
                .foregroundStyle(theme.textPrimary)
            
            Text("你的專屬 AI 助理已準備就緒")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - 底部按鈕
    
    private var footerView: some View {
        HStack {
            // 取消按鈕
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // 錯誤訊息
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            // 主要按鈕
            Button(primaryButtonTitle) {
                handlePrimaryAction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPrimaryButtonDisabled)
        }
        .padding()
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case .input: return "開始生成"
        case .generating: return "生成中..."
        case .selecting: return "下一步"
        case .naming: return "完成"
        case .complete: return "開始使用"
        }
    }
    
    private var isPrimaryButtonDisabled: Bool {
        switch step {
        case .input: return promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .generating: return true
        case .selecting: return selectedImageIndex == nil
        case .naming: return companionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .complete: return false
        }
    }
    
    // MARK: - 操作處理
    
    private func handlePrimaryAction() {
        switch step {
        case .input:
            startGeneration()
        case .generating:
            break
        case .selecting:
            step = .naming
        case .naming:
            createCompanion()
        case .complete:
            dismiss()
        }
    }
    
    private func startGeneration() {
        step = .generating
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                // 使用 Apple Intelligence 生成圖片
                // 注意：實際的圖片生成 API 可能需要調整
                try await generateCompanionImages()
                
                await MainActor.run {
                    isGenerating = false
                    step = .selecting
                }
            } catch {
                await MainActor.run {
                    errorMessage = "生成失敗：\(error.localizedDescription)"
                    isGenerating = false
                    step = .input
                }
            }
        }
    }
    
    private func generateCompanionImages() async throws {
        // TODO: 實際整合 Apple Intelligence 圖片生成 API
        // 目前使用模擬延遲
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 秒模擬
        
        // 在實際實現中，這裡會呼叫圖片生成 API
        // 並將結果存入 generatedImages
        
        // 暫時跳過圖片生成，直接進入命名步驟
        await MainActor.run {
            step = .naming
        }
    }
    
    private func createCompanion() {
        var imageData: [CompanionMood: Data] = [:]
        
        // 如果有選中的圖片，儲存各表情狀態
        if let index = selectedImageIndex, index < generatedImages.count {
            if let tiffData = generatedImages[index].tiffRepresentation {
                // 使用同一張圖片作為所有表情（實際應生成不同表情）
                for mood in CompanionMood.allCases {
                    imageData[mood] = tiffData
                }
            }
        }
        
        let newCompanion = Companion(
            name: companionName,
            description: promptText,
            isDefault: false,
            isActive: false,
            moodImages: imageData,
            tone: .friendly,
            generationPrompt: promptText
        )
        
        service.addCompanion(newCompanion)
        service.setActiveCompanion(newCompanion)
        
        step = .complete
    }
}

// MARK: - Preview

@available(macOS 26.0, *)
#Preview {
    CompanionGeneratorView()
        .environmentObject(AppTheme())
}
