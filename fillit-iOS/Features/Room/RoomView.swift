import SwiftUI
import PhotosUI
import UIKit

struct RoomView: View {
    let roomCode: String
    @State private var viewModel: RoomViewModel
    @Environment(AppRouter.self) private var router
    @State private var photosPickerItem: PhotosPickerItem?

    init(roomCode: String) {
        self.roomCode = roomCode
        self._viewModel = State(initialValue: RoomViewModel(roomCode: roomCode))
    }

    var body: some View {
        ZStack {
            // Layer 0: Background — guarantees no content bleeds through
            Color(uiColor: .systemBackground).ignoresSafeArea()

            // Layer 1: Main content
            Group {
                if viewModel.isLoading {
                    ProgressView("방 불러오는 중...")
                } else if let room = viewModel.room {
                    roomContent(room: room)
                } else {
                    Text("방을 찾을 수 없습니다.").foregroundStyle(.secondary)
                }
            }

            // Layer 2: Upload overlay — naturally above content via ZStack ordering
            if viewModel.isUploading {
                Color.black.opacity(0.35).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)
            }
        }
        .navigationTitle(viewModel.room?.keyword ?? "Fillit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRoom()
            viewModel.startSession()
        }
        .onDisappear { viewModel.stopSession() }
        .onChange(of: viewModel.room?.completed) { _, completed in
            // Guard prevents re-navigation when returning from VoteView with a completed room
            if completed == true && !viewModel.navigatedToVote {
                viewModel.navigatedToVote = true
                router.navigate(to: .vote(code: roomCode))
            }
        }
        .onChange(of: viewModel.isExpired) { _, expired in
            if expired { router.replace(with: .expired) }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            CameraPickerView { image in
                viewModel.uploadImage(image)
            }
        }
        .sheet(isPresented: $viewModel.showUploadSheet) {
            UploadActionSheetView(
                slotIndex: viewModel.selectedSlotIndex ?? 0,
                photosPickerItem: $photosPickerItem,
                includeLocation: $viewModel.includeLocation,
                onCamera: { viewModel.showCamera = true }
            )
        }
        .onChange(of: photosPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.uploadImage(image)
                }
                photosPickerItem = nil
            }
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("마감 임박", isPresented: $viewModel.showDeadlineWarning) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("업로드 마감 1시간 전입니다. 빠르게 사진을 업로드하세요!")
        }
    }

    @ViewBuilder
    private func roomContent(room: Room) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ProgressSection(room: room)

                // Template grid — aspect ratio anchored, never overflows scroll bounds
                TemplatePreviewView(room: room) { slot in
                    viewModel.tapSlot(slot)
                }
                .padding(.horizontal)

                if room.mode == .multi {
                    ParticipantListView(room: room)
                        .padding(.horizontal)
                }

                if viewModel.isHost {
                    InviteSection(room: room)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Upload Action Sheet

private struct UploadActionSheetView: View {
    let slotIndex: Int
    @Binding var photosPickerItem: PhotosPickerItem?
    @Binding var includeLocation: Bool
    let onCamera: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text("슬롯 \(slotIndex + 1)에 사진을 업로드합니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)

            Toggle(isOn: $includeLocation) {
                Label("위치 정보 포함", systemImage: "location")
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("갤러리에서 선택", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .onChange(of: photosPickerItem) { _, item in
                if item != nil { dismiss() }
            }

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onCamera()
                }
            } label: {
                Label("카메라로 촬영", systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Button("취소", role: .cancel) { dismiss() }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Subviews

private struct ProgressSection: View {
    let room: Room
    var progress: (filled: Int, total: Int) { room.progress }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("진행 상황")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(progress.filled)/\(progress.total) 업로드됨")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(progress.filled), total: Double(progress.total))
                .tint(Color.fillitPrimary)
        }
        .padding(.horizontal)
    }
}

private struct ParticipantListView: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("참여자")
                .font(.headline)
            ForEach(room.participants) { participant in
                let slots = room.slots.filter { $0.assignedTo == participant.userId }
                let filled = slots.filter { $0.filled }.count
                HStack {
                    Circle()
                        .fill(participant.userId == room.hostUserId
                              ? Color.fillitPrimary
                              : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(participant.nickname)
                        .font(.subheadline)
                    if participant.userId == room.hostUserId {
                        Text("방장").font(.caption).foregroundStyle(Color.fillitPrimary)
                    }
                    Spacer()
                    Text("\(filled)/\(slots.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .fillitCard()
    }
}

private struct InviteSection: View {
    let room: Room
    @State private var copied = false
    @State private var showShareSheet = false

    private var appURL: URL {
        DeepLinkManager.buildShareURL(room: room)
            ?? URL(string: "fillit://room/\(room.roomCode)")!
    }

    private var shareItems: [Any] {
        [DeepLinkManager.buildWebURL(room: room), DeepLinkManager.buildShareMessage(room: room)]
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("친구 초대하기")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(room.roomCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.fillitPrimary)
                    .frame(maxWidth: .infinity)

                Button {
                    UIPasteboard.general.string = appURL.absoluteString
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(copied ? Color.fillitAccent2 : Color.fillitPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.fillitPrimary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showShareSheet = true
            } label: {
                Label("초대 공유하기", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(items: shareItems)
                    .ignoresSafeArea()
            }
        }
        .padding()
        .fillitCard()
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
