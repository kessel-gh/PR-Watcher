import Foundation
import AppKit // NSWorkspaceを使うために必要

enum Browser: String, CaseIterable, Identifiable, Sendable {
    case systemDefault = "システム標準"
    case chrome = "Google Chrome"
    case safari = "Safari"
    case firefox = "Firefox"
    case arc = "Arc"
    case edge = "Microsoft Edge"
    
    var id: String { self.rawValue }
    
    // Bundle ID (パッケージ名) を返す
    var bundleId: String? {
        switch self {
        case .systemDefault: return nil // nilなら標準を使う
        case .chrome: return "com.google.Chrome"
        case .safari: return "com.apple.Safari"
        case .firefox: return "org.mozilla.firefox"
        case .arc: return "company.thebrowser.Browser"
        case .edge: return "com.microsoft.edgemac"
        }
    }
    
    // URLを指定ブラウザで開くメソッド
    @MainActor
    func open(_ url: URL) {
        if let bundleId = self.bundleId,
           let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            // 指定されたブラウザが見つかった場合
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: config, completionHandler: nil)
        } else {
            // システム標準、または指定ブラウザが見つからない場合は標準で開く
            NSWorkspace.shared.open(url)
        }
    }
}
