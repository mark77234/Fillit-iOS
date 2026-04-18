import SwiftUI

extension Color {
    static let fillitPrimary = Color(red: 0.424, green: 0.388, blue: 1.0)
    static let fillitAccent1 = Color(red: 1.0, green: 0.396, blue: 0.518)
    static let fillitAccent2 = Color(red: 0.263, green: 0.776, blue: 0.675)
    static let fillitAccent3 = Color(red: 1.0, green: 0.820, blue: 0.400)
    static let fillitDark = Color(red: 0.102, green: 0.102, blue: 0.180)
    static let fillitSurface = Color(.systemBackground)
}

extension ShapeStyle where Self == Color {
    static var fillitPrimary: Color { .fillitPrimary }
    static var fillitAccent1: Color { .fillitAccent1 }
    static var fillitAccent2: Color { .fillitAccent2 }
    static var fillitAccent3: Color { .fillitAccent3 }
    static var fillitDark: Color { .fillitDark }
}
