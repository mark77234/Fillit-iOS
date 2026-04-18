import Foundation
import UIKit
import Observation

enum UploadSource { case camera, gallery }

@Observable
final class RoomViewModel {
    var room: Room?
    var isLoading = false
    var isUploading = false
    var showError = false
    var errorMessage = ""
    var selectedSlotIndex: Int?
    var showUploadSheet = false
    var showCamera = false
    var showGallery = false
    var includeLocation = false
    var isExpired = false
    var showDeadlineWarning = false
    var uploadProgress: Double = 0
    var navigatedToVote = false

    private let roomCode: String
    private let getStatusUseCase = GetRoomStatusUseCase()
    private let uploadUseCase = UploadImageUseCase()
    let socketService = SocketService()

    private var pollingTask: Task<Void, Never>?

    init(roomCode: String) {
        self.roomCode = roomCode
    }

    deinit {
        stopPolling()
        socketService.disconnect()
    }

    var mySlots: [Slot] {
        room?.slots.filter { $0.assignedTo == UserSession.shared.userId } ?? []
    }

    var isHost: Bool {
        room?.hostUserId == UserSession.shared.userId
    }

    var isParticipant: Bool {
        room?.isParticipant(userId: UserSession.shared.userId) ?? false
    }

    var inviteURL: String {
        "fillit://join/\(roomCode)"
    }

    func loadRoom() async {
        isLoading = true
        do {
            room = try await getStatusUseCase.execute(code: roomCode)
        } catch {
            setError(error.localizedDescription)
        }
        isLoading = false
    }

    func startSession() {
        setupSocket()
        startPolling()
    }

    func stopSession() {
        stopPolling()
        socketService.disconnect()
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                if let updated = try? await getStatusUseCase.execute(code: roomCode) {
                    await MainActor.run { self.room = updated }
                }
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func setupSocket() {
        socketService.onSlotUpdated = { [weak self] event in
            self?.applySlotUpdate(event)
        }
        socketService.onRoomCompleted = { [weak self] event in
            self?.refreshRoom()
        }
        socketService.onRoomExpired = { [weak self] in
            self?.isExpired = true
        }
        socketService.onDeadlineWarning = { [weak self] in
            self?.showDeadlineWarning = true
        }
        socketService.connect(roomCode: roomCode)
    }

    private func applySlotUpdate(_ event: SlotUpdateEvent) {
        guard var updated = room else { return }
        if let idx = updated.slots.firstIndex(where: { $0.index == event.slotIndex }) {
            updated.slots[idx] = Slot(
                index: event.slotIndex,
                assignedTo: event.assignedTo,
                nickname: event.nickname,
                status: event.status,
                filled: event.filled,
                uploadedAt: event.uploadedAt?.toDate(),
                thumbnailUrl: event.thumbnailUrl,
                location: event.location,
                uploadRank: event.uploadRank
            )
        }
        room = updated
    }

    private func refreshRoom() {
        Task {
            if let updated = try? await getStatusUseCase.execute(code: roomCode) {
                await MainActor.run { self.room = updated }
            }
        }
    }

    func tapSlot(_ slot: Slot) {
        guard slot.assignedTo == UserSession.shared.userId, !slot.filled else { return }
        guard !(room?.uploadLocked ?? true) else {
            setError("업로드 마감 시간이 지났습니다.")
            return
        }
        selectedSlotIndex = slot.index
        showUploadSheet = true
    }

    func uploadImage(_ image: UIImage) {
        guard let slotIndex = selectedSlotIndex else { return }
        isUploading = true
        Task {
            do {
                let response = try await uploadUseCase.execute(
                    code: roomCode,
                    slotIndex: slotIndex,
                    image: image,
                    includeLocation: includeLocation
                )
                if response.completed {
                    await refreshRoomAsync()
                }
            } catch {
                await MainActor.run { setError(error.localizedDescription) }
            }
            await MainActor.run { isUploading = false }
        }
    }

    private func refreshRoomAsync() async {
        if let updated = try? await getStatusUseCase.execute(code: roomCode) {
            await MainActor.run { room = updated }
        }
    }

    func copyRoomCode() -> String { roomCode }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
