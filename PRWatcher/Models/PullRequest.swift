import Foundation
import SwiftUI

struct PullRequest: Decodable, Identifiable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let state: String      // "open", "closed", "merged"
    let htmlUrl: String
    let user: User
    let createdAt: Date
    let draft: Bool?       // ドラフト判定用
    let labels: [GHLabel]
    let reviewDecision: ReviewDecision?
    let reviews: [Review]
    
    enum CodingKeys: String, CodingKey {
        case id, number, title, state, user, draft, labels
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case reviewDecision = "reviewDecision"
        case reviews = "reviews"
    }
    
    // MARK: - Sub Structures
    
    struct User: Decodable, Sendable {
        let login: String
        let avatarUrl: String
        
        enum CodingKeys: String, CodingKey {
            case login
            case avatarUrl = "avatar_url"
        }
    }
    
    struct GHLabel: Decodable, Identifiable, Sendable {
        var id: Int? = nil // GraphQLではIDが必須ではないためOptionalまたはダミー
        let name: String
        let color: String
    }
    
    struct Review: Decodable, Identifiable, Sendable {
        let id: String
        let author: User
        let state: String // "APPROVED", "CHANGES_REQUESTED", "COMMENTED" etc.
        
        var color: Color {
            switch state {
            case "APPROVED": return .green
            case "CHANGES_REQUESTED": return .red
            case "COMMENTED": return .gray
            default: return .secondary
            }
        }
        
        var iconName: String {
            switch state {
            case "APPROVED": return "checkmark.circle.fill"
            case "CHANGES_REQUESTED": return "xmark.circle.fill"
            case "COMMENTED": return "bubble.left.fill"
            default: return "circle"
            }
        }
    }
    
    // 承認ステータス
    enum ReviewDecision: String, Decodable, Sendable {
        case approved = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case reviewRequired = "REVIEW_REQUIRED"
        
        var iconName: String {
            switch self {
            case .approved: return "checkmark.seal.fill"
            case .changesRequested: return "xmark.octagon.fill"
            case .reviewRequired: return "exclamationmark.bubble.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .approved: return .green
            case .changesRequested: return .red
            case .reviewRequired: return .orange
            }
        }
        
        var text: String {
            switch self {
            case .approved: return "Approved"
            case .changesRequested: return "Changes Requested"
            case .reviewRequired: return "Review Required"
            }
        }
    }
    
    // MARK: - Helper Properties
    
    // PR自体の状態（Open/Merged/Closed/Draft）判定
    var statusType: StatusType {
        if state.lowercased() == "merged" { return .merged }
        if state.lowercased() == "closed" { return .closed }
        if draft == true { return .draft }
        return .open
    }
    
    enum StatusType {
        case open, merged, closed, draft
        
        // AssetsまたはSF Symbolsの名前
        var iconName: String {
            switch self {
            case .open: return "git-pull-request"
            case .merged: return "git-merge"
            case .closed: return "git-pull-request-closed"
            case .draft: return "git-pull-request-draft"
            }
        }
        
        var color: Color {
            switch self {
            case .open: return .green
            case .merged: return .purple
            case .closed: return .red
            case .draft: return .gray
            }
        }
        
        var label: String {
            switch self {
            case .open: return "Open"
            case .merged: return "Merged"
            case .closed: return "Closed"
            case .draft: return "Draft"
            }
        }
    }
}
