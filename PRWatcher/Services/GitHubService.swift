import Foundation
import OSLog

/// API通信の責任を持つクラス
struct GitHubService {
    
    private let logger = Logger(subsystem: "com.prwatcher", category: "GitHubService")
    
    enum APIError: Error {
        case invalidURL
        case unauthorized // 401
        case rateLimitExceeded(resetDate: Date) // 403
        case serverError(statusCode: Int)
        case decodingError
        case unknown(Error)
        
        var userMessage: String {
            switch self {
            case .invalidURL: return "不正なURLです"
            case .unauthorized: return "認証に失敗しました。トークンを確認してください"
            case .rateLimitExceeded(let date):
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                return "API制限超過です。解除予定: \(formatter.string(from: date))"
            case .serverError(let code): return "GitHubサーバーエラー (Code: \(code))"
            case .decodingError: return "データの解析に失敗しました"
            case .unknown(let error): return "予期せぬエラー: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchPullRequests(token: String, query: String, urlString: String) async throws -> [PullRequest] {
        // 引数で渡された urlString を使用してURLを作成
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        // GraphQL Query
        let graphqlQuery = """
        query($query: String!) {
          search(query: $query, type: ISSUE, first: 30) {
            nodes {
              ... on PullRequest {
                databaseId
                number
                title
                state
                url
                createdAt
                isDraft
                reviewDecision
                author { login avatarUrl }
                labels(first: 10) { nodes { name color } }
                latestReviews(first: 10) {
                  nodes {
                    id
                    state
                    author { login avatarUrl }
                  }
                }
              }
            }
          }
        }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PRWatcher-App", forHTTPHeaderField: "User-Agent")
        
        let body: [String: Any] = [
            "query": graphqlQuery,
            "variables": ["query": query]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let graphqlResponse = try decoder.decode(GraphQLResponse.self, from: data)
                
                return graphqlResponse.data.search.nodes.compactMap { node -> PullRequest? in
                    let user = PullRequest.User(
                        login: node.author?.login ?? "Ghost",
                        avatarUrl: node.author?.avatarUrl ?? ""
                    )
                    
                    let reviews = node.latestReviews?.nodes.compactMap { reviewNode -> PullRequest.Review? in
                        guard let author = reviewNode.author else { return nil }
                        return PullRequest.Review(
                            id: reviewNode.id,
                            author: PullRequest.User(login: author.login, avatarUrl: author.avatarUrl),
                            state: reviewNode.state
                        )
                    } ?? []
                    
                    return PullRequest(
                        id: node.databaseId,
                        number: node.number,
                        title: node.title,
                        state: node.state,
                        htmlUrl: node.url,
                        user: user,
                        createdAt: node.createdAt,
                        draft: node.isDraft,
                        labels: node.labels.nodes.map {
                            PullRequest.GHLabel(id: nil, name: $0.name, color: $0.color)
                        },
                        reviewDecision: PullRequest.ReviewDecision(rawValue: node.reviewDecision ?? ""),
                        reviews: reviews
                    )
                }
            } catch {
                logger.error("Decoding Error: \(error.localizedDescription)")
                throw APIError.decodingError
            }
            
        case 401:
            logger.warning("Unauthorized access (401). Token might be invalid.")
            throw APIError.unauthorized
            
        case 403:
            if let remaining = httpResponse.value(forHTTPHeaderField: "x-ratelimit-remaining"),
               remaining == "0",
               let resetTimeStr = httpResponse.value(forHTTPHeaderField: "x-ratelimit-reset"),
               let resetTimeInterval = TimeInterval(resetTimeStr) {
                let resetDate = Date(timeIntervalSince1970: resetTimeInterval)
                throw APIError.rateLimitExceeded(resetDate: resetDate)
            }
            logger.error("Forbidden access (403) but not rate limit.")
            throw APIError.serverError(statusCode: 403)
            
        default:
            logger.error("Server Error: Status Code \(httpResponse.statusCode)")
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Private GraphQL Response Structures
private struct GraphQLResponse: Decodable {
    let data: DataContainer
}
private struct DataContainer: Decodable {
    let search: SearchResultContainer
}
private struct SearchResultContainer: Decodable {
    let nodes: [PRNode]
}
private struct PRNode: Decodable {
    let databaseId: Int
    let number: Int
    let title: String
    let state: String
    let url: String
    let createdAt: Date
    let isDraft: Bool
    let reviewDecision: String?
    let author: Author?
    let labels: LabelContainer
    let latestReviews: ReviewContainer?
    
    struct Author: Decodable { let login: String; let avatarUrl: String }
    struct LabelContainer: Decodable { let nodes: [LabelNode] }
    struct LabelNode: Decodable { let name: String; let color: String }
    struct ReviewContainer: Decodable { let nodes: [ReviewNode] }
    struct ReviewNode: Decodable {
        let id: String
        let state: String
        let author: Author?
    }
}
