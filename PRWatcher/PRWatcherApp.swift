import SwiftUI

@main
struct PRWatcherApp: App {
    var body: some Scene {
        // WindowGroup ではなく MenuBarExtra を使います
        // systemImageは SF Symbols のアイコン名です (例: "eyeglasses", "list.bullet" など)
        MenuBarExtra("Review Monitor", systemImage: "eye") {
            // ここでContentViewを呼び出すだけ！
            ContentView()
        }
        // これをつけると、クリック時にリストのようなウィンドウが表示されます（おすすめ）
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "settings") {
            SettingsView()
                .frame(width: 450, height: 250) // サイズ指定
                .fixedSize() // リサイズ不可にする（設定画面っぽく）
        }
        .windowResizability(.contentSize) // ウィンドウサイズをコンテンツに合わせる
        .defaultSize(width: 450, height: 250) // デフォルトサイズ
    }
}
