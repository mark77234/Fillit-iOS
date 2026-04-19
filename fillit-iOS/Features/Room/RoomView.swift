import SwiftUI
import PhotosUI

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
    @State private var showInstagramSheet = false
    @State private var isInstagramAvailable = false

    private var appURL: URL { DeepLinkManager.buildAppURL(room: room) }
    private var shareItems: [Any] {
        [DeepLinkManager.buildWebURL(room: room), DeepLinkManager.buildShareMessage(room: room)]
    }

    // Official Instagram gradient: purple → red → orange (bottom-left → top-right)
    private let igGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0.51, green: 0.23, blue: 0.70), location: 0),
            .init(color: Color(red: 0.99, green: 0.11, blue: 0.11), location: 0.5),
            .init(color: Color(red: 0.97, green: 0.47, blue: 0.21), location: 1),
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

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

            HStack(spacing: 10) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showShareSheet) {
                    ActivityShareSheet(items: shareItems).ignoresSafeArea()
                }

                if isInstagramAvailable {
                    Button {
                        showInstagramSheet = true
                    } label: {
                        Image("Instagram_Glyph_White")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(igGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showInstagramSheet) {
                        ActivityShareSheet(
                            items: [makeShareCard(), DeepLinkManager.buildShareMessage(room: room)]
                        ).ignoresSafeArea()
                    }
                }
            }
        }
        .padding()
        .fillitCard()
        .onAppear {
            isInstagramAvailable = UIApplication.shared.canOpenURL(URL(string: "instagram://")!)
        }
    }

    private func makeShareCard() -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // Dark purple → near-black gradient background
            let bgColors = [UIColor(red: 0.10, green: 0.02, blue: 0.22, alpha: 1).cgColor,
                            UIColor(red: 0.03, green: 0.01, blue: 0.10, alpha: 1).cgColor] as CFArray
            let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0, 1])!
            cgCtx.drawLinearGradient(bgGrad, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            // Centered text helper — returns line height
            func centered(_ text: String, font: UIFont, color: UIColor, y: CGFloat) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let s = NSAttributedString(string: text, attributes: attrs)
                let maxW = size.width - 120
                let b = s.boundingRect(with: CGSize(width: maxW, height: .greatestFiniteMagnitude),
                                       options: .usesLineFragmentOrigin, context: nil)
                s.draw(in: CGRect(x: (size.width - b.width) / 2, y: y, width: b.width, height: b.height))
                return b.height
            }

            // Left-aligned text helper — returns line height
            func left(_ text: String, font: UIFont, color: UIColor, x: CGFloat, y: CGFloat) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let s = NSAttributedString(string: text, attributes: attrs)
                let maxW = size.width - x - 60
                let b = s.boundingRect(with: CGSize(width: maxW, height: .greatestFiniteMagnitude),
                                       options: .usesLineFragmentOrigin, context: nil)
                s.draw(in: CGRect(x: x, y: y, width: maxW, height: b.height))
                return b.height
            }

            // App icon
            let iconSz: CGFloat = 200
            let iconX = (size.width - iconSz) / 2
            let iconY: CGFloat = 160
            if let icon = UIImage(named: "ic_fillit") {
                let r = CGRect(x: iconX, y: iconY, width: iconSz, height: iconSz)
                let path = UIBezierPath(roundedRect: r, cornerRadius: 46)
                cgCtx.saveGState()
                path.addClip()
                icon.draw(in: r)
                cgCtx.restoreGState()
                cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.18).cgColor)
                cgCtx.setLineWidth(2)
                path.stroke()
            }

            var y: CGFloat = iconY + iconSz + 36
            y += centered("Fillit", font: .systemFont(ofSize: 74, weight: .bold), color: .white, y: y) + 14
            y += centered("소중한 순간들을 함께 채워보세요",
                          font: .systemFont(ofSize: 36, weight: .regular),
                          color: UIColor.white.withAlphaComponent(0.55), y: y) + 64

            // Room code card
            let pad: CGFloat = 60
            let cardRect = CGRect(x: pad, y: y, width: size.width - pad * 2, height: 440)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 36)
            UIColor.white.withAlphaComponent(0.07).setFill(); cardPath.fill()
            UIColor.white.withAlphaComponent(0.14).setStroke(); cardPath.lineWidth = 1.5; cardPath.stroke()

            let dim = UIColor.white.withAlphaComponent(0.5)
            var cy = y + 52
            cy += centered("방 코드", font: .systemFont(ofSize: 34, weight: .semibold), color: dim, y: cy) + 18
            cy += centered(room.roomCode, font: .monospacedSystemFont(ofSize: 108, weight: .bold), color: .white, y: cy) + 24
            var infoLine = room.mode.rawValue
            if let kw = room.keyword, !kw.isEmpty { infoLine = "\(kw)  ·  \(infoLine)" }
            infoLine += "  ·  슬롯 \(room.totalSlots)개"
            _ = centered(infoLine, font: .systemFont(ofSize: 34, weight: .medium), color: dim, y: cy)

            y = cardRect.maxY + 50
            let host = room.participants.first(where: { $0.userId == room.hostUserId })?.nickname ?? ""
            if !host.isEmpty {
                y += centered("방장: \(host)", font: .systemFont(ofSize: 38, weight: .medium),
                              color: UIColor.white.withAlphaComponent(0.7), y: y) + 52
            } else { y += 52 }

            // Divider
            UIColor.white.withAlphaComponent(0.14).setStroke()
            let div = UIBezierPath(); div.lineWidth = 1
            div.move(to: CGPoint(x: pad, y: y)); div.addLine(to: CGPoint(x: size.width - pad, y: y)); div.stroke()
            y += 50

            // Links
            let accent = UIColor(red: 0.98, green: 0.38, blue: 0.52, alpha: 1)
            let lx = pad + 20
            let labelF = UIFont.systemFont(ofSize: 30, weight: .semibold)
            let linkF  = UIFont.systemFont(ofSize: 30, weight: .regular)
            let linkColor = UIColor.white.withAlphaComponent(0.58)

            y += left("👉  앱으로 참여하기", font: labelF, color: accent, x: lx, y: y) + 10
            y += left(DeepLinkManager.buildAppURL(room: room).absoluteString,
                      font: linkF, color: linkColor, x: lx, y: y) + 36

            y += left("🌐  웹으로 참여하기", font: labelF, color: accent, x: lx, y: y) + 10
            y += left("fillit.today/room/\(room.roomCode)", font: linkF, color: linkColor, x: lx, y: y) + 36

            y += left("📲  앱 다운로드", font: labelF, color: accent, x: lx, y: y) + 10
            _ = left("apps.apple.com/app/id6762511564", font: linkF, color: linkColor, x: lx, y: y)

            // Bottom Instagram-style gradient bar
            let barH: CGFloat = 10
            let barY = size.height - 110
            let barRect = CGRect(x: pad, y: barY, width: size.width - pad * 2, height: barH)
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: barH / 2)
            cgCtx.saveGState()
            barPath.addClip()
            let igC = [UIColor(red: 0.51, green: 0.23, blue: 0.70, alpha: 1).cgColor,
                       UIColor(red: 0.99, green: 0.11, blue: 0.11, alpha: 1).cgColor,
                       UIColor(red: 0.97, green: 0.47, blue: 0.21, alpha: 1).cgColor] as CFArray
            let igG = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: igC, locations: [0, 0.5, 1])!
            cgCtx.drawLinearGradient(igG,
                                     start: CGPoint(x: pad, y: barY),
                                     end: CGPoint(x: size.width - pad, y: barY),
                                     options: [])
            cgCtx.restoreGState()

            _ = centered("fillit.today", font: .systemFont(ofSize: 30, weight: .medium),
                         color: UIColor.white.withAlphaComponent(0.28), y: size.height - 68)
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
