import Foundation

struct Template: Codable, Identifiable {
    let id: String
    let name: String
    let canvas: TemplateCanvas
    let slots: [TemplateSlot]

    var aspectRatio: Double {
        canvas.width / canvas.height
    }
}

struct TemplateCanvas: Codable {
    let width: Double
    let height: Double
}

struct TemplateSlot: Codable, Identifiable {
    var id: Int { index }
    let index: Int
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}
