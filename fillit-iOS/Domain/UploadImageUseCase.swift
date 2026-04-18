import Foundation
import UIKit
import CoreLocation

final class UploadImageUseCase {
    private let roomService = RoomService()
    private let geoService = GeoService()
    private let locationService = LocationService()

    func execute(
        code: String,
        slotIndex: Int,
        image: UIImage,
        includeLocation: Bool
    ) async throws -> UploadResponse {
        let userId = UserSession.shared.userId
        var locationString: String?

        if includeLocation {
            if let loc = try? await locationService.requestLocation() {
                locationString = try? await geoService.reverseGeocode(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
            }
        }

        return try await roomService.uploadImage(
            code: code,
            slotIndex: slotIndex,
            userId: userId,
            image: image,
            location: locationString
        )
    }
}
