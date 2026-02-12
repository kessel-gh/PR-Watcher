# PR Watcher

macOSのメニューバー常駐型アプリです。
自分に関連するプルリクエスト（レビュー依頼、自分のPR、アサイン済み）を素早く確認できます。

<img width="406" height="510" alt="スクリーンショット 2026-02-12 21 42 15" src="https://github.com/user-attachments/assets/b3086b4f-1020-4ab7-ac63-1ccec45a1810" />

## 特徴

- **高速な確認:** GitHub GraphQL APIを使用し、最小限の通信でステータスを取得。
- **ステータス可視化:** Approve / Changes Requested / Commented などのレビュー状況をアイコンで表示。
- **GHE対応:** GitHub Enterprise環境でも利用可能（設定画面でURL変更可）。
- **Vibe Coding:** AIとのペアプログラミングを活用して開発。

## 技術スタック

- Swift 6 / SwiftUI
- Combine / Concurrency (async/await)
- GitHub GraphQL API
- macOS (Menu Bar App)

## 使い方

1. [Releases](../../releases) から最新のアプリをダウンロードします。
2. アプリを起動し、環境設定（`Cmd + ,`）を開きます。
3. GitHubで発行した **Personal Access Token (Classic)** を入力します。
   - 必要な権限: `repo`, `read:org`, `read:user`
4. メニューバーのアイコンをクリックしてPRを確認できます。

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。
