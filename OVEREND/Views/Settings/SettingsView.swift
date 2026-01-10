//
//  SettingsView.swift
//  OVEREND
//
//  設置視圖
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("一般", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("外觀", systemImage: "paintpalette")
                }

            BibTeXSettingsView()
                .tabItem {
                    Label("BibTeX", systemImage: "doc.text")
                }
            
            DataManagementView()
                .tabItem {
                    Label("資料管理", systemImage: "cylinder")
                }
            
            ProxySettingsView()
                .tabItem {
                    Label("校外連線", systemImage: "network")
                }
            
            #if DEBUG
            NotionSettingsView()
                .tabItem {
                    Label("Notion", systemImage: "tablecells")
                }
            #endif
            
            AISettingsView()
                .tabItem {
                    Label("AI", systemImage: "apple.intelligence")
                }
        }
        .frame(width: 650, height: 500)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("OVEREND macOS 版本 1.0.0")
                    .font(.headline)

                Text("讓研究者專注於研究本身，而不是文獻管理")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        Form {
            Picker("外觀模式", selection: $appearanceMode) {
                Text("跟隨系統").tag("system")
                Text("淺色").tag("light")
                Text("深色").tag("dark")
            }
            .pickerStyle(.radioGroup)
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct BibTeXSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("BibTeX 設置")
                    .font(.headline)

                Text("未來版本將支持自定義 Citation Key 格式、匯出選項等。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
