import SwiftUI

struct ExpiredView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 80))
                .foregroundStyle(Color.fillitAccent1)

            VStack(spacing: 12) {
                Text("방이 만료되었습니다")
                    .font(.title2.weight(.bold))
                Text("해당 방은 더 이상 접근할 수 없습니다.\n새로운 방을 만들어보세요!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                router.popToRoot()
            } label: {
                Label("홈으로 돌아가기", systemImage: "house.fill")
                    .font(.body.weight(.semibold))
            }
            .primaryButton()
            .padding(.horizontal, 60)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}
