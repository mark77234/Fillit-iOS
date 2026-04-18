import SwiftUI

extension View {
    func fillitCard() -> some View {
        self
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    func primaryButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.fillitPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.35)
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.white)
                }
                .ignoresSafeArea()
            }
        }
    }
}

struct FillitTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
