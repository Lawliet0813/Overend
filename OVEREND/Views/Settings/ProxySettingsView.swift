//
//  ProxySettingsView.swift
//  OVEREND
//
//  Created by Antigravity on 2025/12/28.
//

import SwiftUI

struct ProxySettingsView: View {
    @StateObject private var networkService = NetworkService.shared
    
    var body: some View {
        Form {
            Section(header: Text("校外連線設定 (VPN/Proxy)")) {
                Text("若您需要從校外存取學術資料庫，請在此設定學校圖書館的 Proxy 前綴網址。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Proxy URL 前綴", text: $networkService.proxyURLPrefix)
                    .textFieldStyle(.roundedBorder)
                
                Text("例如: https://ezproxy.lib.ntu.edu.tw/login?url=")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 500, height: 200)
    }
}
