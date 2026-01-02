//
//  AppIconPreview.swift
//  OVEREND
//
//  App Icon 預覽和導出視圖
//

import SwiftUI

/// OVEREND App Icon 設計
struct OVERENDAppIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // 背景：品牌綠色漸層
            RoundedRectangle(cornerRadius: size * 0.225) // macOS 標準圓角
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#00D97E"),  // 主色
                            Color(hex: "#00B368")   // 深色
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 主圖案：堆疊書籍 + 學術符號
            VStack(spacing: 0) {
                // 上半部：書籍堆疊
                ZStack {
                    // 第三本書（最下層）- 稍微大一點，角度偏右
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.52, height: size * 0.11)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: size * 0.04)
                                .offset(x: -size * 0.24)
                        )
                        .shadow(color: .black.opacity(0.15), radius: size * 0.015, y: size * 0.01)
                        .rotationEffect(.degrees(3))
                        .offset(x: size * 0.04, y: size * 0.02)

                    // 第二本書（中層）- 水平
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.5, height: size * 0.11)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: size * 0.04)
                                .offset(x: -size * 0.23)
                        )
                        .shadow(color: .black.opacity(0.18), radius: size * 0.018, y: size * 0.012)
                        .offset(y: -size * 0.01)

                    // 第一本書（最上層）- 角度偏左
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.48, height: size * 0.11)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: size * 0.04)
                                .offset(x: -size * 0.22)
                        )
                        .shadow(color: .black.opacity(0.2), radius: size * 0.02, y: size * 0.015)
                        .rotationEffect(.degrees(-6))
                        .offset(x: -size * 0.06, y: -size * 0.04)
                }
                .offset(y: -size * 0.08)

                // 下半部：引用/學術符號
                Text("\" \"")
                    .font(.system(size: size * 0.35, weight: .black, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.25), radius: size * 0.02, x: 0, y: size * 0.02)
                    .offset(y: size * 0.08)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Icon 導出助手視圖
struct AppIconExportView: View {
    @State private var selectedSize: CGFloat = 1024

    let sizes: [(name: String, size: CGFloat)] = [
        ("1024x1024 (App Store)", 1024),
        ("512x512", 512),
        ("256x256", 256),
        ("128x128", 128),
        ("64x64", 64),
        ("32x32", 32),
        ("16x16", 16)
    ]

    var body: some View {
        VStack(spacing: 32) {
            Text("OVEREND App Icon")
                .font(.system(size: 28, weight: .bold))

            // Icon 預覽
            OVERENDAppIcon(size: min(selectedSize, 512))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            // 尺寸選擇
            VStack(alignment: .leading, spacing: 12) {
                Text("選擇尺寸：")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Picker("Size", selection: $selectedSize) {
                    ForEach(sizes, id: \.size) { item in
                        Text(item.name).tag(item.size)
                    }
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: 600)

            // 使用說明
            VStack(alignment: .leading, spacing: 12) {
                Text("📝 使用說明")
                    .font(.system(size: 16, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow("1", "在 Xcode 中打開此預覽")
                    instructionRow("2", "選擇想要的尺寸")
                    instructionRow("3", "對圖標截圖（⌘⇧4，然後空格鍵）")
                    instructionRow("4", "將圖片拖入 Assets.xcassets → AppIcon")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.textBackgroundColor))
            )
            .frame(maxWidth: 600)

            Spacer()
        }
        .padding(40)
        .frame(width: 800, height: 900)
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 批量生成所有尺寸（用於 Preview）

struct AllIconSizesPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("所有 macOS App Icon 尺寸")
                    .font(.system(size: 24, weight: .bold))

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 32) {
                    iconPreviewItem(size: 1024, label: "1024x1024\n(App Store)")
                    iconPreviewItem(size: 512, label: "512x512\n(@2x)")
                    iconPreviewItem(size: 256, label: "256x256\n(@1x)")
                    iconPreviewItem(size: 128, label: "128x128")
                    iconPreviewItem(size: 64, label: "64x64")
                    iconPreviewItem(size: 32, label: "32x32")
                    iconPreviewItem(size: 16, label: "16x16")
                }
                .padding(.horizontal, 40)

                Text("💡 提示：右鍵點擊圖標 → 「將圖像拷貝」，然後貼到 AppIcon.appiconset")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(.vertical, 40)
        }
        .frame(width: 1000, height: 1200)
    }

    private func iconPreviewItem(size: CGFloat, label: String) -> some View {
        VStack(spacing: 12) {
            OVERENDAppIcon(size: min(size, 256))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 預覽

#Preview("Icon Export Helper") {
    AppIconExportView()
}

#Preview("All Sizes") {
    AllIconSizesPreview()
}

#Preview("1024x1024 Icon Only") {
    ZStack {
        Color(.windowBackgroundColor)
            .ignoresSafeArea()

        OVERENDAppIcon(size: 1024)
            .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
    }
    .frame(width: 1200, height: 1200)
}
