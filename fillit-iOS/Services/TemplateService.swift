import Foundation

final class TemplateService {
    private let api = APIClient.shared

    func getTemplates() async throws -> [Template] {
        let response: TemplatesResponse = try await api.get("api/templates")
        return response.templates
    }
}
