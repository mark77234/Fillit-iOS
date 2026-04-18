import SwiftUI

struct TemplatePreviewView: View {
    let room: Room
    let onSlotTap: (Slot) -> Void

    private let baseURL = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String)
        ?? "https://fillit-production.up.railway.app"

    var body: some View {
        // Color.clear로 올바른 aspect ratio 기반 frame을 확보한 뒤
        // overlay 안의 GeometryReader가 그 정확한 크기(width + height)를 읽음.
        // ScrollView 안에서 GeometryReader를 단독으로 쓰면 height = ∞ 버그가 발생하지만
        // overlay 방식은 부모(Color.clear)의 frame을 그대로 상속하므로 안전.
        Color.clear
            .aspectRatio(room.template.aspectRatio, contentMode: .fit)
            .overlay(
                GeometryReader { geo in
                    gridContent(width: geo.size.width, height: geo.size.height)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func gridContent(width: CGFloat, height: CGFloat) -> some View {
        let gap: CGFloat = 2

        ZStack(alignment: .topLeading) {
            // Layer 0: 배경
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: width, height: height)

            // Layer 1: 슬롯 카드들 (절대 좌표 배치)
            ForEach(room.template.slots) { templateSlot in
                if let slot = room.slots.first(where: { $0.index == templateSlot.index }) {
                    let slotW = templateSlot.w / 100 * width
                    let slotH = templateSlot.h / 100 * height
                    let slotX = templateSlot.x / 100 * width
                    let slotY = templateSlot.y / 100 * height

                    SlotCardView(
                        slot: slot,
                        baseURL: baseURL,
                        isMySlot: slot.assignedTo == UserSession.shared.userId,
                        onTap: { onSlotTap(slot) }
                    )
                    // gap만큼 줄여서 인접 슬롯 간 틈 확보
                    .frame(width: slotW - gap, height: slotH - gap)
                    // .position은 ZStack 좌표계에서 뷰 중심을 지정
                    .position(x: slotX + slotW / 2, y: slotY + slotH / 2)
                }
            }
        }
        // ZStack 전체를 그리드 bounds 안에 고정 + 넘침 클립
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
