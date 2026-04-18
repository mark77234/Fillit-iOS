import Foundation
import Observation

enum DeadlinePreset: String, CaseIterable {
    case none = "없음"
    case oneHour = "1시간"
    case threeHours = "3시간"
    case sixHours = "6시간"
    case midnight = "오늘 자정"
    case custom = "직접 설정"
}

@Observable
final class CreateRoomViewModel {
    var templates: [Template] = []
    var selectedTemplateId = ""
    var mode: RoomMode = .multi
    var participantLimit = 2
    var nickname = ""
    var keyword = ""
    var deadlinePreset: DeadlinePreset = .none
    var customDeadline = Date().addingTimeInterval(3600)
    var isLoading = false
    var isLoadingTemplates = false
    var showError = false
    var errorMessage = ""

    private let useCase = CreateRoomUseCase()

    var selectedTemplate: Template? {
        templates.first { $0.id == selectedTemplateId }
    }

    var canCreate: Bool {
        !selectedTemplateId.isEmpty
            && !nickname.trimmingCharacters(in: .whitespaces).isEmpty
            && !keyword.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var maxParticipants: Int {
        selectedTemplate?.slots.count ?? 8
    }

    var resolvedDeadline: Date? {
        switch deadlinePreset {
        case .none: return nil
        case .oneHour: return Date().addingTimeInterval(3600)
        case .threeHours: return Date().addingTimeInterval(10800)
        case .sixHours: return Date().addingTimeInterval(21600)
        case .midnight:
            var cal = Calendar.current
            cal.timeZone = TimeZone.current
            return cal.startOfDay(for: Date()).addingTimeInterval(86400)
        case .custom: return customDeadline
        }
    }

    var keywordPresets: [String] {
        ["여행", "생일", "모임", "졸업", "맛집", "페스티벌", "스포츠", "데이트"]
    }

    func loadTemplates() async {
        isLoadingTemplates = true
        do {
            templates = try await useCase.getTemplates()
            if let first = templates.first {
                selectedTemplateId = first.id
            }
        } catch {
            setError(error.localizedDescription)
        }
        isLoadingTemplates = false
    }

    func createRoom(router: AppRouter) async {
        guard canCreate else { return }
        let name = nickname.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { setError("닉네임을 입력해 주세요."); return }

        isLoading = true
        do {
            let slots = mode == .solo ? (selectedTemplate?.slots.count ?? 4) : participantLimit
            let response = try await useCase.execute(
                templateId: selectedTemplateId,
                mode: mode,
                totalSlots: slots,
                hostNickname: name,
                keyword: keyword.isEmpty ? nil : keyword,
                deadlineAt: resolvedDeadline
            )
            await MainActor.run {
                router.navigate(to: .room(code: response.roomCode))
            }
        } catch {
            setError(error.localizedDescription)
        }
        isLoading = false
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
