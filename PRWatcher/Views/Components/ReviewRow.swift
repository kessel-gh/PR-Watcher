import SwiftUI
import AppKit

struct ReviewRow: View {
    let pr: PullRequest
    @AppStorage("selectedBrowser") private var selectedBrowser: Browser = .systemDefault
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 1. ステータスアイコン
            VStack(spacing: 4) {
                Image(pr.statusType.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(pr.statusType.color)
                
                Text(pr.statusType.label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(pr.statusType.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 32)
            .padding(.top, 4)
            
            // 2. メイン情報
            VStack(alignment: .leading, spacing: 5) {
                
                // A. ヘッダー
                HStack(alignment: .center, spacing: 8) {
                    if let repoName = extractRepoName(from: pr.htmlUrl) {
                        Text(repoName)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                    
                    Text("#\(pr.number)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(pr.createdAt.relativeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // B. タイトル
                Text(pr.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // C. フッター
                HStack(alignment: .center, spacing: 10) {
                    
                    // レビュー状況
                    if let decision = pr.reviewDecision {
                        HStack(spacing: 4) {
                            Image(systemName: decision.iconName)
                                .font(.system(size: 10, weight: .bold))
                            Text(decision.text)
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundColor(decision.color)
                    }
                    
                    // レビュワー
                    if !pr.reviews.isEmpty {
                        HStack(spacing: -6) {
                            ForEach(pr.reviews) { review in
                                AsyncImage(url: URL(string: review.author.avatarUrl)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
                                }
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(review.color, lineWidth: 1)
                                )
                                .help("\(review.author.login): \(review.state)")
                            }
                        }
                    }
                    
                    // ラベルリスト
                    if !pr.labels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(pr.labels, id: \.name) { label in
                                    Text(label.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: label.color).opacity(0.85)) // 背景色
                                    // 背景が明るいなら黒文字、暗いなら白文字にする
                                        .foregroundColor(isLightColor(label.color) ? .black.opacity(0.8) : .white)
                                        .cornerRadius(3)
                                        .overlay(
                                            // 明るい色の場合は境界がぼやけるので薄い枠線を追加
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.black.opacity(0.1), lineWidth: isLightColor(label.color) ? 1 : 0)
                                        )
                                }
                            }
                        }
                        .frame(height: 16)
                    }
                }
            }
            
            // 3. 右端: アバター
            AsyncImage(url: URL(string: pr.user.avatarUrl)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            .help("Author: \(pr.user.login)")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
    
    private func extractRepoName(from url: String) -> String? {
        let parts = url.components(separatedBy: "/")
        guard parts.count >= 5 else { return nil }
        return "\(parts[3])/\(parts[4])"
    }
    
    // 色の明るさを判定するメソッド
    private func isLightColor(_ hex: String) -> Bool {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            return false
        }
        
        // 輝度(Luminance)を計算 (0.0 〜 1.0)
        // 一般的な計算式: 0.299R + 0.587G + 0.114B
        let brightness = (Double(r) * 0.299 + Double(g) * 0.587 + Double(b) * 0.114) / 255.0
        
        // 明るさが0.6以上なら「明るい色（白文字だと見にくい）」と判定
        return brightness > 0.6
    }
}
