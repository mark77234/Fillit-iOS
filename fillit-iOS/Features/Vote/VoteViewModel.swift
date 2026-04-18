import Foundation
import Observation

@Observable
final class VoteViewModel {
    var room: Room?
    var isLoading = false
    var isVoting = false
    var isEndingVote = false
    var showError = false
    var errorMessage = ""
    var myVotedSlotIndex: Int?
    var voteDeadline: Date?
    var showVotingComplete = false

    private let roomCode: String
    private let getStatusUseCase = GetRoomStatusUseCase()
    private let voteUseCase = VoteUseCase()
    let socketService = SocketService()

    private var pollingTask: Task<Void, Never>?

    init(roomCode: String) {
        self.roomCode = roomCode
    }

    deinit {
        pollingTask?.cancel()
        socketService.disconnect()
    }

    var isHost: Bool {
        room?.hostUserId == UserSession.shared.userId
    }

    var hasVoted: Bool {
        room?.hasMyVote ?? false
    }

    var filledSlots: [Slot] {
        room?.slots.filter { $0.filled } ?? []
    }

    var voteCount: Int {
        room?.voteCompletedCount ?? 0
    }

    var totalParticipants: Int {
        room?.participants.count ?? 0
    }

    func loadRoom() async {
        isLoading = true
        do {
            room = try await getStatusUseCase.execute(code: roomCode)
            myVotedSlotIndex = room?.votes.first { $0.voterId == UserSession.shared.userId }?.targetSlotIndex
            voteDeadline = room?.votingDeadlineAt
        } catch {
            setError(error.localizedDescription)
        }
        isLoading = false
    }

    func startSession(router: AppRouter) {
        setupSocket(router: router)
        startPolling()
    }

    func stopSession() {
        pollingTask?.cancel()
        socketService.disconnect()
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                if let updated = try? await getStatusUseCase.execute(code: roomCode) {
                    await MainActor.run {
                        room = updated
                        myVotedSlotIndex = updated.votes.first { $0.voterId == UserSession.shared.userId }?.targetSlotIndex
                    }
                }
            }
        }
    }

    private func setupSocket(router: AppRouter) {
        socketService.onVoteUpdated = { [weak self] event in
            guard var r = self?.room else { return }
            r.voteCompletedCount = event.completedCount
            self?.room = r
        }
        socketService.onVotingCompleted = { [weak self] event in
            guard var r = self?.room else { return }
            r.votingCompleted = true
            r.voteRanking = event.voteRanking
            r.uploadRanking = event.uploadRanking
            self?.room = r
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                router.navigate(to: .rankResult(code: self?.roomCode ?? ""))
            }
        }
        socketService.connect(roomCode: roomCode)
    }

    func submitVote(slotIndex: Int) {
        guard !hasVoted else { return }
        isVoting = true
        Task {
            do {
                _ = try await voteUseCase.submitVote(code: roomCode, targetSlotIndex: slotIndex)
                myVotedSlotIndex = slotIndex
                if let updated = try? await getStatusUseCase.execute(code: roomCode) {
                    room = updated
                }
            } catch {
                setError(error.localizedDescription)
            }
            isVoting = false
        }
    }

    func skipVote() {
        isVoting = true
        Task {
            do {
                _ = try await voteUseCase.submitVote(code: roomCode, targetSlotIndex: -1)
                await MainActor.run { myVotedSlotIndex = -1 }
            } catch {
                await MainActor.run { setError(error.localizedDescription) }
            }
            await MainActor.run { isVoting = false }
        }
    }

    func endVote(router: AppRouter) {
        isEndingVote = true
        Task {
            do {
                _ = try await voteUseCase.endVote(code: roomCode)
                await MainActor.run { router.navigate(to: .rankResult(code: roomCode)) }
            } catch {
                await MainActor.run { setError(error.localizedDescription) }
            }
            await MainActor.run { isEndingVote = false }
        }
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
