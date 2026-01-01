//
//  LaTeXFormulaSheet.swift
//  OVEREND
//
//  LaTeX 公式插入介面
//

import SwiftUI

/// LaTeX 公式插入面板
struct LaTeXFormulaSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    @State private var formulaText: String = ""
    @State private var selectedTemplate: FormulaTemplate?
    @State private var previewImage: NSImage?
    @State private var errorMessage: String?
    @State private var isRendering = false

    // AI 輔助生成
    @State private var showAIGenerator = false
    @State private var aiDescription: String = ""
    @State private var isGenerating = false

    var onInsert: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Image(systemName: "function")
                    .font(.title2)
                    .foregroundColor(theme.accent)

                Text("插入 LaTeX 公式")
                    .font(.title2.weight(.bold))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.toolbar)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // AI 智慧生成（新功能！）
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(theme.accent)
                            Text("AI 智慧生成")
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            if AppleAIService.shared.isAvailable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .help("Apple Intelligence 可用")
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .help("Apple Intelligence 不可用")
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("描述公式（例如：「畢氏定理」）", text: $aiDescription)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13))

                            Button(action: generateWithAI) {
                                HStack(spacing: 4) {
                                    if isGenerating {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text("生成")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(aiDescription.isEmpty || isGenerating || !AppleAIService.shared.isAvailable)
                        }

                        Text("提示：用自然語言描述公式，AI 會自動轉換為 LaTeX")
                            .font(.caption)
                            .foregroundColor(theme.textMuted)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.accentLight)
                    )

                    Divider()

                    // 快速模板
                    VStack(alignment: .leading, spacing: 8) {
                        Text("快速模板")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            ForEach(FormulaTemplate.allCases, id: \.self) { template in
                                TemplateButton(template: template) {
                                    selectedTemplate = template
                                    formulaText = template.formula
                                }
                            }
                        }
                    }

                    Divider()

                    // 公式輸入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("公式（LaTeX 語法）")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)

                        TextEditor(text: $formulaText)
                            .font(.system(size: 14, design: .monospaced))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(theme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.border, lineWidth: 1)
                            )

                        HStack {
                            Text("提示：使用 $ 包圍公式，例如 $E=mc^2$")
                                .font(.caption)
                                .foregroundColor(theme.textMuted)

                            Spacer()

                            Button(action: renderPreview) {
                                HStack(spacing: 4) {
                                    if isRendering {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "eye")
                                    }
                                    Text("預覽")
                                }
                                .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(formulaText.isEmpty || isRendering)
                        }
                    }

                    // 預覽區域
                    if let previewImage = previewImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("預覽")
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)

                            HStack {
                                Spacer()
                                Image(nsImage: previewImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 100)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                        }
                    }

                    // 錯誤訊息
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            // 底部按鈕
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("插入") {
                    onInsert(formulaText)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(formulaText.isEmpty)
            }
            .padding()
            .background(theme.toolbar)
        }
        .frame(width: 600, height: 600)
        .background(theme.background)
    }

    private func renderPreview() {
        isRendering = true
        errorMessage = nil
        previewImage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = LaTeXRenderer.render(formula: formulaText, fontSize: 16)

            DispatchQueue.main.async {
                isRendering = false

                switch result {
                case .success(let image):
                    previewImage = image
                case .error(let message):
                    errorMessage = message
                }
            }
        }
    }

    /// AI 生成公式
    private func generateWithAI() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let latex = try await AILatexGenerator.generateFormula(from: aiDescription)

                await MainActor.run {
                    formulaText = "$\(latex)$"
                    isGenerating = false

                    // 自動預覽
                    renderPreview()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "AI 生成失敗：\(error.localizedDescription)"
                }
            }
        }
    }
}

/// LaTeX 公式模板
enum FormulaTemplate: String, CaseIterable {
    case quadratic = "二次方程式"
    case fraction = "分數"
    case integral = "積分"
    case summation = "求和"
    case matrix = "矩陣"
    case squareRoot = "平方根"

    var formula: String {
        switch self {
        case .quadratic:
            return "$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$"
        case .fraction:
            return "$\\frac{a}{b}$"
        case .integral:
            return "$\\int_0^\\infty e^{-x^2} dx$"
        case .summation:
            return "$\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}$"
        case .matrix:
            return "$\\begin{bmatrix} a & b \\\\ c & d \\end{bmatrix}$"
        case .squareRoot:
            return "$\\sqrt{x^2 + y^2}$"
        }
    }

    var icon: String {
        switch self {
        case .quadratic: return "x.squareroot"
        case .fraction: return "divide"
        case .integral: return "function"
        case .summation: return "sum"
        case .matrix: return "square.grid.2x2"
        case .squareRoot: return "square.root"
        }
    }
}

/// 模板按鈕
struct TemplateButton: View {
    @EnvironmentObject var theme: AppTheme
    let template: FormulaTemplate
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(theme.accent)

                Text(template.rawValue)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.accentLight : theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    LaTeXFormulaSheet { formula in
        print("Inserted: \(formula)")
    }
    .environmentObject(AppTheme())
}
