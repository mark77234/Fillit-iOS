import SwiftUI
import Kingfisher

struct RankResultView: View {
    let roomCode: String
    @State private var viewModel: RankResultViewModel
    @Environment(AppRouter.self) private var router

    init(roomCode: String) {
        self.roomCode = roomCode
        self._viewModel = State(initialValue: RankResultViewModel(roomCode: roomCode))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Ranked collage image
                if let imageURL = viewModel.rankedImageURL ?? viewModel.defaultImageURL {
                    KFImage(imageURL)
                        .placeholder { ProgressView() }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Vote ranking
                if let room = viewModel.room, !room.voteRanking.isEmpty {
                    UploadRankingView(
                        voteRanking: room.voteRanking,
                        slots: room.slots,
                        baseURL: viewModel.baseURL
                    )
                    .padding(.horizontal)
                }

                // Navigate to result
                Button(action: { router.navigate(to: .result(code: roomCode)) }) {
    ZStack {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.fillitPrimary)
            .frame(height: 50)
        Label("다운로드 / 공유로 이동", systemImage: "arrow.down.circle.fill")
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
    }
}
.buttonStyle(.plain)
.padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("투표 결과")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.loadRoom() }
        .loadingOverlay(viewModel.isLoading)
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
