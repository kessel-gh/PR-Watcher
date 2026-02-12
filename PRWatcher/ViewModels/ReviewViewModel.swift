import Foundation
import SwiftUI
import Combine

// プロトコルを切っておく（テスト用モックを作れるようにするため）
protocol GitHubServiceProtocol {
    func fetchPullRequests(token: String, query: String, urlString: String) async throws -> [PullRequest]
}

// GitHubServiceに準拠させる
extension GitHubService: GitHubServiceProtocol {}

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [PullRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 設定画面と同期する値
    @AppStorage("selectedFilter") var selectedFilter: FilterType = .reviewRequested
    
    // GHE用の設定
    @AppStorage("useEnterprise") private var useEnterprise = false
    @AppStorage("enterpriseURL") private var enterpriseURL = ""
    
    private let githubService: GitHubServiceProtocol
    
    init(service: GitHubServiceProtocol? = nil) {
        self.githubService = service ?? GitHubService()
    }
    
    private var keychainToken: String {
        KeychainHelper.shared.read(account: "githubToken") ?? ""
    }
    
    // 設定に基づいて接続先URLを決定する
    private var currentAPIEndpoint: String {
        if useEnterprise {
            // 末尾の余計なスペースや改行を除去して返す
            return enterpriseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "https://api.github.com/graphql"
        }
    }
    
    func fetchReviews() async {
        // トークン未設定時のガード
        guard !keychainToken.isEmpty else {
            self.errorMessage = "設定画面(Cmd+,)からGitHubトークンを設定してください 🔑"
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Serviceを使ってデータを取得
            let items = try await githubService.fetchPullRequests(
                token: keychainToken,
                query: selectedFilter.query,
                urlString: currentAPIEndpoint
            )
            
            self.reviews = items
            
        } catch let error as GitHubService.APIError {
            // Service側で定義したユーザーフレンドリーなメッセージを表示
            self.errorMessage = error.userMessage
            
            // エラーログ出力（デバッグ用）
            switch error {
            case .unauthorized:
                print("Token might be expired or invalid.")
            case .rateLimitExceeded(let resetDate):
                print("Rate limit hits. Reset at: \(resetDate)")
            default:
                break
            }
            
        } catch {
            // その他の予期せぬエラー
            self.errorMessage = "予期せぬエラー: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
