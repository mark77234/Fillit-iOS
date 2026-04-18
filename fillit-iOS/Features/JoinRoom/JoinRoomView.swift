import SwiftUI

struct JoinRoomView: View {
    let roomCode: String
    @State private var viewModel = JoinRoomViewModel()
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let room = viewModel.room {
                    // Room info card
                    VStack(spacing: 16) {
                        Text("방 정보")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 20) {
                            InfoItem(label: "방 코드", value: room.roomCode)
                            InfoItem(label: "모드", value: room.mode == .multi ? "다같이 찍기" : "혼자 찍기")
                            InfoItem(label: "슬롯", value: "\(room.totalSlots)개")
                        }

                        if let keyword = room.keyword, !keyword.isEmpty {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.fillitPrimary)
                                Text(keyword)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Participants
                        VStack(alignment: .leading, spacing: 6) {
                            Text("참여자 (\(room.participants.count)/\(room.participantLimit)명)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(room.participants) { p in
                                        Text(p.nickname)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.fillitPrimary.opacity(0.12))
                                            .foregroundStyle(Color.fillitPrimary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .fillitCard()

                    // Nickname input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("닉네임 입력")
                            .font(.headline)

                        @Bindable var vm = viewModel
                        TextField("닉네임을 입력하세요", text: $vm.nickname)
                            .textFieldStyle(FillitTextFieldStyle())
                            .onChange(of: viewModel.nickname) { _, v in
                                viewModel.nickname = String(v.prefix(30))
                            }
                    }

                    Button {
                        Task { await viewModel.join(code: roomCode, router: router) }
                    } label: {
                        if viewModel.isJoining {
                            ProgressView().tint(.white)
                        } else {
                            Text("참여하기").font(.body.weight(.semibold))
                        }
                    }
                    .primaryButton()
                    .disabled(!viewModel.canJoin || viewModel.isJoining)
                    .opacity(!viewModel.canJoin ? 0.5 : 1)
                }
            }
            .padding()
        }
        .navigationTitle("방 참여")
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(viewModel.isLoading)
        .task { await viewModel.loadRoom(code: roomCode) }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.fillitPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
