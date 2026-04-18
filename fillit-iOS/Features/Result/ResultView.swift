import SwiftUI
import Kingfisher
import AVKit

struct ResultView: View {
    let roomCode: String
    @State private var viewModel: ResultViewModel
    @Environment(AppRouter.self) private var router

    init(roomCode: String) {
        self.roomCode = roomCode
        self._viewModel = State(initialValue: ResultViewModel(roomCode: roomCode))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Countdown
                if let room = viewModel.room {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                        Text("만료까지: \(room.expiresAt.timeUntilString)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Result image
                if let imageURL = viewModel.defaultImageURL {
                    KFImage(imageURL)
                        .placeholder { ProgressView() }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Top voted
                if let (slot, score) = viewModel.topVotedSlot, let thumbUrl = slot.thumbnailUrl {
                    TopVotedView(
                        thumbnailURL: URL(string: viewModel.baseURL + thumbUrl),
                        nickname: slot.nickname ?? "",
                        score: score,
                        location: slot.location
                    )
                    .padding(.horizontal)
                }

                // Download options
                DownloadOptionsView(viewModel: viewModel)
                    .padding(.horizontal)

                // Create new
                Button {
                    router.popToRoot()
                    router.navigate(to: .createRoom)
                } label: {
                    Label("새 방 만들기", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
            // 홈으로 돌아가기 버튼
            Button(action: {
                router.popToRoot()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.fillitPrimary)
                        .frame(height: 50)
                    Label("홈으로 돌아가기", systemImage: "house.fill")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("결과 보기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.loadRoom() }
        .loadingOverlay(viewModel.isLoading || viewModel.isDownloading)
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct TopVotedView: View {
    let thumbnailURL: URL?
    let nickname: String
    let score: Int
    let location: String?

    var body: some View {
        HStack(spacing: 16) {
            KFImage(thumbnailURL)
                .placeholder { Color.gray.opacity(0.3) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Label("최다 득표", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(Color.fillitAccent3)
                Text(nickname)
                    .font(.headline)
                Text("\(score)표")
                    .font(.subheadline)
                    .foregroundStyle(Color.fillitPrimary)
                if let loc = location {
                    Label(loc, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .fillitCard()
    }
}

private struct DownloadOptionsView: View {
    @Bindable var viewModel: ResultViewModel

    private let variants: [(String, ResultVariant, String)] = [
        ("기본", .default, "photo"),
        ("스토리 (9:16)", .story, "iphone"),
        ("와이드 (16:9)", .wide, "rectangle"),
        ("랭킹 포함", .ranked, "trophy")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다운로드 / 공유")
                .font(.headline)

            ForEach(variants, id: \.1.rawValue) { title, variant, icon in
                HStack {
                    Label(title, systemImage: icon)
                    Spacer()
                    Button("저장") {
                        viewModel.saveToPhotos(variant: variant)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.fillitPrimary)
                    .clipShape(Capsule())

                    Button("공유") {
                        viewModel.download(variant: variant)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.fillitPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.fillitPrimary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Reel
            VStack(alignment: .leading, spacing: 10) {
                Label("릴 (영상)", systemImage: "video")
                    .font(.subheadline.weight(.medium))

                HStack {
                    Text("속도:")
                    ForEach([0.5, 1.0, 2.0, 4.0], id: \.self) { speed in
                        Button("\(speed == 0.5 ? "0.5" : speed == 1.0 ? "1" : speed == 2.0 ? "2" : "4")x") {
                            viewModel.reelSpeed = speed
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(viewModel.reelSpeed == speed ? .white : Color.fillitPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.reelSpeed == speed ? Color.fillitPrimary : Color.fillitPrimary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    Spacer()
                    Button("공유") {
                        viewModel.download(variant: .reel)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.fillitPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.fillitPrimary.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
