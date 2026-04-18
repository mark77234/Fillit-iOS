import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case decodingError(Error)
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다."
        case .invalidResponse(let code): return "서버 오류 (\(code))"
        case .decodingError(let err): return "데이터 파싱 오류: \(err.localizedDescription)"
        case .networkError(let err): return err.localizedDescription
        case .serverError(let msg): return msg
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    let baseURL: URL
    private let session: URLSession
    let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://fillit-production.up.railway.app"
        baseURL = URL(string: urlString)!
        session = URLSession.shared

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f1.date(from: str) { return d }
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let d = f2.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    func upload<T: Decodable>(_ path: String, imageData: Data, fields: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipart(imageData: imageData, fields: fields, boundary: boundary)
        return try await perform(request)
    }

    func downloadData(_ path: String, query: [String: String] = [:]) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse(0)
            }
            guard (200..<300).contains(http.statusCode) else {
                if let msg = try? JSONDecoder().decode(ServerErrorBody.self, from: data) {
                    throw APIError.serverError(msg.message)
                }
                throw APIError.invalidResponse(http.statusCode)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func buildMultipart(imageData: Data, fields: [String: String], boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        for (key, value) in fields {
            body.appendString("--\(boundary)\(crlf)")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(crlf)\(crlf)")
            body.appendString("\(value)\(crlf)")
        }
        body.appendString("--\(boundary)\(crlf)")
        body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(crlf)")
        body.appendString("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        body.appendString("\(crlf)--\(boundary)--\(crlf)")
        return body
    }
}

private struct ServerErrorBody: Decodable {
    let message: String
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
