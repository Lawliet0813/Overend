//
//  LibraryAgentComponents.swift
//  OVEREND
//
//  AI 助理側邊欄元件 - 從 EmeraldLibrarySubviews 拆分
//
//

import SwiftUI

// MARK: - AI 助理側邊欄區塊

@available(macOS 26.0, *)
struct AgentSidebarSection: View {
    @EnvironmentObject var theme: AppTheme
    let libraries: [Library]
    
    @ObservedObject private var agent = LiteratureAgent.shared
    @State private var isExpanded = false
    
    private var currentLibrary: Library? {
        libraries.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "cpu")
                            .font(.system(size: 14))
                            .foregroundColor(theme.accent)
                    }
                    
                    Text("AI 助理")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.accent)
                    
                    Spacer()
                    
                    if agent.state.isExecuting {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 8) {
                    AgentQuickButton(
                        icon: "folder.badge.gearshape",
                        title: "智慧分類",
                        isLoading: agent.state == .classifying
                    ) {
                        if let library = currentLibrary {
                            Task {
                                try? await agent.execute(task: .organizeByTopic(library))
                            }
                        }
                    }
                    
                    AgentQuickButton(
                        icon: "tag.fill",
                        title: "自動標籤",
                        isLoading: agent.state == .tagging
                    ) {
                        if let library = currentLibrary {
                            let context = PersistenceController.shared.container.viewContext
                            let entries = Entry.fetchAll(in: library, context: context)
                            Task {
                                try? await agent.execute(task: .autoTagEntries(entries))
                            }
                        }
                    }
                    
                    AgentQuickButton(
                        icon: "doc.on.doc",
                        title: "尋找重複",
                        isLoading: agent.state == .analyzing
                    ) {
                        if let library = currentLibrary {
                            Task {
                                try? await agent.execute(task: .findDuplicates(library))
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if !agent.pendingSuggestions.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("\(agent.pendingSuggestions.count) 個建議待確認")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [theme.accent.opacity(0.05), theme.surfaceDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accent.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Agent 快速按鈕

@available(macOS 26.0, *)
struct AgentQuickButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 18)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHovered ? .white : theme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isHovered ? theme.accent.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
