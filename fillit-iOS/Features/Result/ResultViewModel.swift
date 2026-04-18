import Foundation
import UIKit
import PhotosUI
import Observation

@Observable
final class ResultViewModel {
    var room: Room?
    var isLoading = false
    var isDownloading = false
    var showError = false
    var errorMessage = ""
    var downloadProgress: String = ""
    var showShareSheet = false
    var shareItems: [Any] = []
    var reelSpeed: Double = 1.0

    private let roomCode: String
    private let getStatusUseCase = GetRoomStatusUseCase()
    private let roomService = RoomService()

    init(roomCode: String) {
        self.roomCode = roomCode
    }

    var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "http://localhost:3000"
    }

    var defaultImageURL: URL? {
        guard let path = room?.resultUrl else { return nil }
        return URL(string: baseURL + path)
    }

    var topVotedSlot: (slot: Slot, score: Int)? {
        guard let room, let top = room.voteRanking.first(where: { $0.rank == 1 }) else { return nil }
        guard let slot = room.slots.first(where: { $0.index == top.slotIndex }) else { return nil }
        return (slot, top.score)
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

    func download(variant: ResultVariant) {
        isDownloading = true
        downloadProgress = "다운로드 중..."

        Task {
            do {
                let speed = variant == .reel ? reelSpeed : nil
                let data = try await roomService.downloadResult(code: roomCode, variant: variant, reelSpeed: speed)

                await MainActor.run {
                    let tempURL: URL
                    if variant == .reel {
                        tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("fillit_reel.mp4")
                    } else {
                        tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("fillit_result.jpg")
                    }
                    try? data.write(to: tempURL)
                    shareItems = [tempURL]
                    showShareSheet = true
                    isDownloading = false
                    downloadProgress = ""
                }
            } catch {
                await MainActor.run {
                    setError(error.localizedDescription)
                    isDownloading = false
                    downloadProgress = ""
                }
            }
        }
    }

    func saveToPhotos(variant: ResultVariant) {
        isDownloading = true
        Task {
            do {
                let speed = variant == .reel ? reelSpeed : nil
                let data = try await roomService.downloadResult(code: roomCode, variant: variant, reelSpeed: speed)

                if variant == .reel {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fillit_reel.mp4")
                    try? data.write(to: url)
                    await MainActor.run {
                        shareItems = [url]
                        showShareSheet = true
                        isDownloading = false
                    }
                } else if let image = UIImage(data: data) {
                    await MainActor.run {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        isDownloading = false
                    }
                }
            } catch {
                await MainActor.run {
                    setError(error.localizedDescription)
                    isDownloading = false
                }
            }
        }
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
