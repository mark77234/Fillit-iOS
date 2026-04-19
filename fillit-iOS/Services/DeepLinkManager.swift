import Foundation
import Observation

@Observable
final class DeepLinkManager {
    static let shared = DeepLinkManager()
    private init() {}

    var pendingRoomCode: String?

    func handle(url: URL) {
        let roomId: String?

        if url.scheme == "fillit" {
            roomId = url.pathComponents.last(where: { $0 != "/" && !$0.isEmpty })
        } else {
            let parts = url.pathComponents
            if let idx = parts.firstIndex(of: "room"), idx + 1 < parts.count {
                roomId = parts[idx + 1]
            } else {
                roomId = nil
            }
        }

        guard let id = roomId, id.count == 6 else { return }
        pendingRoomCode = id.uppercased()
    }

    // fillit://room/{roomCode}?m=multi&kw=생일&sc=2&h=병찬
    static func buildAppURL(room: Room) -> URL {
        var components = URLComponents()
        components.scheme = "fillit"
        components.host = "room"
        components.path = "/\(room.roomCode)"

        let hostNickname = room.participants.first(where: { $0.userId == room.hostUserId })?.nickname ?? ""

        var items: [URLQueryItem] = [
            .init(name: "m", value: room.mode.rawValue),
            .init(name: "sc", value: "\(room.totalSlots)"),
            .init(name: "h", value: hostNickname),
        ]
        if let keyword = room.keyword, !keyword.isEmpty {
            items.insert(.init(name: "kw", value: keyword), at: 1)
        }
        components.queryItems = items
        return components.url ?? URL(string: "fillit://room/\(room.roomCode)")!
    }

    static func buildWebURL(room: Room) -> URL {
        URL(string: "https://fillit.today/room/\(room.roomCode)") ?? URL(string: "https://fillit.today")!
    }

    static func buildShareMessage(room: Room) -> String {
        let hostNickname = room.participants.first(where: { $0.userId == room.hostUserId })?.nickname ?? ""
        let participantNames = room.participants.map { $0.nickname }.joined(separator: ", ")
        let appLink = buildAppURL(room: room).absoluteString
        let webLink = buildWebURL(room: room).absoluteString

        var lines: [String] = [
            "📸 Fillit 방 초대",
            "",
            "방 코드: \(room.roomCode)",
            "모드: \(room.mode == .multi ? "다같이" : "혼자")",
        ]
        if let keyword = room.keyword, !keyword.isEmpty {
            lines.append("키워드: \(keyword)")
        }
        lines += [
            "슬롯: \(room.totalSlots)개",
            "참여자: \(participantNames)",
            "방장: \(hostNickname)",
            "",
            "👉 참여하기",
            "앱: \(appLink)",
            "",
            "웹: \(webLink)",
            "",
            "📲 앱 다운로드",
            "https://apps.apple.com/us/app/fillit-fill-the-frame/id6762511564",
        ]
        return lines.joined(separator: "\n")
    }
}
