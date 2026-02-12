import Foundation

enum FilterType: String, CaseIterable, Identifiable, Sendable {
    case reviewRequested = "レビュー依頼"
    case createdByMe = "自分のPR"
    case assigned = "アサイン済み"
    
    var id: String { self.rawValue }
    
    // GitHub APIへの検索クエリ
    var query: String {
        switch self {
        case .reviewRequested:
            // 自分(@me)にレビュー依頼が来ている OpenなPR
            return "is:pr is:open review-requested:@me"
            
        case .createdByMe:
            // 自分(@me)が作成した OpenなPR
            return "is:pr is:open author:@me"
            
        case .assigned:
            // 自分(@me)にアサインされている OpenなPR
            return "is:pr is:open assignee:@me"
        }
    }
}
