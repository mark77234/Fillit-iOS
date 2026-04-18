import Foundation
import CoreLocation

final class GeoService {
    private let api = APIClient.shared

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String? {
        let response: ReverseGeocodeResponse = try await api.get(
            "api/geo/reverse",
            query: ["lat": "\(latitude)", "lon": "\(longitude)"]
        )
        return response.location
    }
}
