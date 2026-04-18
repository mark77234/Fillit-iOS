import Foundation
import SocketIO
import Observation

@Observable
final class SocketService {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let decoder = JSONDecoder()

    var isConnected = false

    var onSlotUpdated: ((SlotUpdateEvent) -> Void)?
    var onRoomCompleted: ((RoomCompleteEvent) -> Void)?
    var onVotingStarted: ((VotingStartEvent) -> Void)?
    var onVoteUpdated: ((VoteUpdateEvent) -> Void)?
    var onVotingCompleted: ((VotingCompleteEvent) -> Void)?
    var onRoomExpired: (() -> Void)?
    var onDeadlineWarning: (() -> Void)?

    init() {
        decoder.dateDecodingStrategy = .iso8601
    }

    func connect(roomCode: String) {
        disconnect()
        let socketURL = Bundle.main.object(forInfoDictionaryKey: "SOCKET_BASE_URL") as? String ?? "https://fillit-production.up.railway.app"
        guard let url = URL(string: socketURL) else { return }

        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectWait(5),
            .reconnectAttempts(-1)
        ])
        socket = manager?.defaultSocket
        setupHandlers(roomCode: roomCode)
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        isConnected = false
    }

    private func setupHandlers(roomCode: String) {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.socket?.emit("join_room", roomCode)
            }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async { self?.isConnected = false }
        }

        socket?.on("slot_updated") { [weak self] data, _ in
            self?.decode(data: data, handler: self?.onSlotUpdated)
        }

        socket?.on("room_completed") { [weak self] data, _ in
            self?.decode(data: data, handler: self?.onRoomCompleted)
        }

        socket?.on("voting_started") { [weak self] data, _ in
            self?.decode(data: data, handler: self?.onVotingStarted)
        }

        socket?.on("vote_updated") { [weak self] data, _ in
            self?.decode(data: data, handler: self?.onVoteUpdated)
        }

        socket?.on("voting_completed") { [weak self] data, _ in
            self?.decode(data: data, handler: self?.onVotingCompleted)
        }

        socket?.on("room_expired") { [weak self] _, _ in
            DispatchQueue.main.async { self?.onRoomExpired?() }
        }

        socket?.on("deadline_warning") { [weak self] _, _ in
            DispatchQueue.main.async { self?.onDeadlineWarning?() }
        }
    }

    private func decode<T: Decodable>(data: [Any], handler: ((T) -> Void)?) {
        guard let dict = data.first as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let event = try? decoder.decode(T.self, from: jsonData) else { return }
        DispatchQueue.main.async { handler?(event) }
    }
}
