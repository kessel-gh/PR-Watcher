import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReviewViewModel()
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HeaderView(viewModel: viewModel, openWindow: openWindow)
            
            Divider()
            
            // コンテンツ
            ContentArea(viewModel: viewModel, openWindow: openWindow)
        }
        .frame(width: 400, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            Task { await viewModel.fetchReviews() }
        }
        // macOS 14+ 対応: 引数を2つ (_, newPhase) にする
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.fetchReviews() }
            }
        }
    }
}

// MARK: - Subviews

struct HeaderView: View {
    @ObservedObject var viewModel: ReviewViewModel
    let openWindow: OpenWindowAction
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("PR Watcher")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    Task { await viewModel.fetchReviews() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help("更新")
                .disabled(viewModel.isLoading)
                
                Menu {
                    Text("PR Watcher v1.0.0").font(.caption)
                    Divider()
                    Button("環境設定...") {
                        openWindow(id: "settings")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    Divider()
                    Button("終了する") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterType.allCases) { type in
                        FilterChip(type: type, selectedFilter: $viewModel.selectedFilter) {
                            Task { await viewModel.fetchReviews() }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 32)
            .padding(.bottom, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct FilterChip: View {
    let type: FilterType
    @Binding var selectedFilter: FilterType
    let action: () -> Void
    
    var body: some View {
        let isSelected = (selectedFilter == type)
        
        Text(type.rawValue)
            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: isSelected ? 0 : 1)
            )
            .cornerRadius(12)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedFilter = type
                }
                action()
            }
    }
}

struct ContentArea: View {
    @ObservedObject var viewModel: ReviewViewModel
    let openWindow: OpenWindowAction
    
    // ブラウザ設定
    @AppStorage("selectedBrowser") private var selectedBrowser: Browser = .systemDefault
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxHeight: .infinity)
                
            } else if let error = viewModel.errorMessage {
                ErrorView(error: error, openWindow: openWindow)
                
            } else if viewModel.reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.8))
                    Text("確認するPRはありません 🎉")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
                
            } else {
                List(viewModel.reviews) { pr in
                    Button {
                        // Browser.swift に open メソッドを追加すればここが通ります
                        openInBrowser(url: URL(string: pr.htmlUrl)!)
                    } label: {
                        ReviewRow(pr: pr)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
    }
    
    private func openInBrowser(url: URL) {
        selectedBrowser.open(url)
    }
}

struct ErrorView: View {
    let error: String
    let openWindow: OpenWindowAction
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(spacing: 4) {
                Text("読み込みエラー")
                    .font(.headline)
                Text(error)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("設定を確認する") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .controlSize(.large)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}
