import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var githubToken = ""
    @AppStorage("selectedBrowser") private var selectedBrowser: Browser = .systemDefault
    
    @AppStorage("useEnterprise") private var useEnterprise = false
    @AppStorage("enterpriseURL") private var enterpriseURL = ""
    
    // 初期値は false (固定値) にして、初期化エラーを回避
    @State private var launchAtLogin: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("GitHub設定")) {
                SecureField("Personal Access Token", text: $githubToken)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: githubToken) { _, newValue in
                        KeychainHelper.shared.save(newValue, account: "githubToken")
                    }
                
                Text("GitHubで発行したトークン(classic)を入力してください。\n必要な権限: repo, read:org")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("接続先") {
                Toggle("GitHub Enterpriseを使用", isOn: $useEnterprise)
                
                if useEnterprise {
                    TextField("GraphQL エンドポイント URL", text: $enterpriseURL)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                    
                    Text("例: https://github.example.com/api/graphql")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("アプリ設定")) {
                Picker("ブラウザ", selection: $selectedBrowser) {
                    ForEach(Browser.allCases) { browser in
                        Text(browser.rawValue).tag(browser)
                    }
                }
                
                Toggle("Mac起動時に自動で開く", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("起動設定の変更に失敗しました: \(error)")
                            // エラー時はスイッチを元の状態に戻す（オプション）
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
        }
        .padding(20)
        .onAppear {
            if let token = KeychainHelper.shared.read(account: "githubToken") {
                self.githubToken = token
            }
        }
    }
}
