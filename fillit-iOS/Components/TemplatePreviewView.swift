import SwiftUI

struct TemplatePreviewView: View {
    let room: Room
    let onSlotTap: (Slot) -> Void

    private let baseURL = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String) ?? "http://localhost:3000"

    var body: some View {
        GeometryReader { geo in
            let canvasAspect = room.template.canvas.width / room.template.canvas.height
            let viewWidth = geo.size.width
            let viewHeight = viewWidth / canvasAspect

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: viewWidth, height: viewHeight)

                ForEach(room.template.slots) { templateSlot in
                    if let slot = room.slots.first(where: { $0.index == templateSlot.index }) {
                        let x = templateSlot.x / 100 * viewWidth
                        let y = templateSlot.y / 100 * viewHeight
                        let w = templateSlot.w / 100 * viewWidth
                        let h = templateSlot.h / 100 * viewHeight

                        SlotCardView(
                            slot: slot,
                            baseURL: baseURL,
                            isMySlot: slot.assignedTo == UserSession.shared.userId,
                            onTap: { onSlotTap(slot) }
                        )
                        .frame(width: w - 3, height: h - 3)
                        .position(x: x + w / 2, y: y + h / 2)
                    }
                }
            }
            .frame(height: viewHeight)
        }
        .aspectRatio(room.template.aspectRatio, contentMode: .fit)
    }
}
