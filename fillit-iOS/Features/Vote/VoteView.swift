import SwiftUI
import Kingfisher

struct VoteView: View {
    let roomCode: String
    @State private var viewModel: VoteViewModel
    @Environment(AppRouter.self) private var router
    private let baseURL = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String) ?? "http://localhost:3000"

    init(roomCode: String) {
        self.roomCode = roomCode
        self._viewModel = State(initialValue: VoteViewModel(roomCode: roomCode))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header info
                VStack(spacing: 6) {
                    if let keyword = viewModel.room?.keyword, !keyword.isEmpty {
                        Text(keyword)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.fillitPrimary)
                    }
                    Text("\(viewModel.voteCount)/\(viewModel.totalParticipants)명 투표 완료")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let deadline = viewModel.voteDeadline {
                        CountdownView(deadline: deadline)
                    }
                }

                // Skip / status
                if viewModel.hasVoted {
                    Label("투표 완료!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.fillitAccent2)
                        .font(.subheadline.weight(.medium))
                } else {
                    Button("투표 건너뛰기") {
                        viewModel.skipVote()
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }

                // Photo grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.filledSlots) { slot in
                        VoteCardView(
                            slot: slot,
                            baseURL: baseURL,
                            isSelected: viewModel.myVotedSlotIndex == slot.index,
                            hasVoted: viewModel.hasVoted
                        ) {
                            viewModel.submitVote(slotIndex: slot.index)
                        }
                    }
                }
                .padding(.horizontal)

                // Host: end vote button
                if viewModel.isHost {
                    Button(action: { viewModel.endVote(router: router) }) {
    ZStack {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.fillitPrimary)
            .frame(height: 50)
        if viewModel.isEndingVote {
            ProgressView().tint(.white)
        } else {
            Text("투표 종료").font(.body.weight(.semibold)).foregroundColor(.white)
        }
    }
}
.buttonStyle(.plain)
.disabled(viewModel.isEndingVote)
.padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("투표하기")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadRoom()
            viewModel.startSession(router: router)
        }
        .onDisappear { viewModel.stopSession() }
        .loadingOverlay(viewModel.isLoading || viewModel.isVoting)
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
