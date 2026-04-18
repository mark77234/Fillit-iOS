import Foundation

extension Date {
    var timeUntilString: String {
        let diff = timeIntervalSinceNow
        guard diff > 0 else { return "만료됨" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60

        if hours > 0 {
            return String(format: "%d시간 %02d분", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d분 %02d초", minutes, seconds)
        } else {
            return String(format: "%d초", seconds)
        }
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: self)
    }
}

extension String {
    func toDate() -> Date? {
        let formattersWithMs = ISO8601DateFormatter()
        formattersWithMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formattersWithMs.date(from: self) { return d }

        let formatterNoMs = ISO8601DateFormatter()
        formatterNoMs.formatOptions = [.withInternetDateTime]
        return formatterNoMs.date(from: self)
    }
}
