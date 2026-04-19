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

    static func buildShareURL(room: Room, source: String = "direct") -> URL? {
        var components = URLComponents()
        components.scheme = "fillit"
        components.host = "room"
        components.path = "/\(room.roomCode)"

        let hostNickname = room.participants.first(where: { $0.userId == room.hostUserId })?.nickname ?? ""
        let participantNames = room.participants.map { $0.nickname }.joined(separator: ",")

        components.queryItems = [
            .init(name: "mode", value: room.mode.rawValue),
            .init(name: "keyword", value: room.keyword ?? ""),
            .init(name: "slotCount", value: "\(room.totalSlots)"),
            .init(name: "participants", value: participantNames),
            .init(name: "host", value: hostNickname),
            .init(name: "appStore", value: "https://apps.apple.com/us/app/fillit-fill-the-frame/id6762511564"),
            .init(name: "web", value: "https://fillit.today/"),
            .init(name: "shareSource", value: source),
        ]
        return components.url
    }

    static func buildWebURL(room: Room) -> URL {
        URL(string: "https://fillit.today/room/\(room.roomCode)") ?? URL(string: "https://fillit.today")!
    }

    static func buildShareMessage(room: Room) -> String {
        let hostNickname = room.participants.first(where: { $0.userId == room.hostUserId })?.nickname ?? ""
        let participantNames = room.participants.map { $0.nickname }.joined(separator: ", ")
        let deepLink = buildShareURL(room: room)?.absoluteString ?? "https://fillit.today/room/\(room.roomCode)"
        let webLink = "https://fillit.today/room/\(room.roomCode)"

        var lines: [String] = [
            "📸 Fillit 방 초대",
            "",
            "방 코드: \(room.roomCode)",
            "모드: \(room.mode.rawValue)",
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
            "앱: \(deepLink)",
            "",
            "웹: \(webLink)",
            "",
            "📲 앱 다운로드",
            "https://apps.apple.com/us/app/fillit-fill-the-frame/id6762511564",
            "",
            "🌐 설치 없이 참여",
            "https://fillit.today/",
        ]
        return lines.joined(separator: "\n")
    }
}
