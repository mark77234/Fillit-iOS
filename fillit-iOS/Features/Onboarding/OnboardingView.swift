import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "",
            heroImageName: "ic_fillit",
            title: "Fillit",
            description: "소중한 순간들을\n함께 채워보세요",
            showSkip: true
        ),
        OnboardingSlide(
            icon: "square.grid.2x2",
            title: "템플릿 선택",
            description: "원하는 그리드 형태를\n자유롭게 선택하세요",
            showSkip: false
        ),
        OnboardingSlide(
            icon: "figure.2.and.child.holdinghands",
            title: "다양한 상황에서",
            description: "여행, 생일, 모임, 졸업 등\n어떤 순간도 담을 수 있어요",
            showSkip: false
        ),
        OnboardingSlide(
            icon: "tag.fill",
            title: "키워드 투표",
            description: "주제 키워드를 설정하고\n가장 잘 어울리는 사진에 투표하세요",
            showSkip: false
        ),
        OnboardingSlide(
            icon: "person.2.fill",
            title: "친구 초대",
            description: "6자리 코드로\n친구들을 간편하게 초대하세요",
            showSkip: false
        ),
        OnboardingSlide(
            icon: "hand.thumbsup.fill",
            title: "투표 & 결과",
            description: "모든 슬롯이 채워지면\n투표하고 결과를 확인하세요",
            showSkip: false
        ),
        OnboardingSlide(
            icon: "sparkles",
            title: "지금 시작해보세요!",
            description: "나만의 특별한 포토 콜라주를\n완성해보세요",
            showSkip: false
        )
    ]

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(slides.indices, id: \.self) { index in
                        OnboardingSlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(slides.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.fillitPrimary : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 20 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }

                    HStack(spacing: 12) {
                        if currentPage > 0 {
                            Button("이전") {
                                withAnimation { currentPage -= 1 }
                            }
                            .foregroundStyle(.secondary)
                            .frame(width: 80, height: 44)
                        } else if slides[currentPage].showSkip {
                            Button("건너뛰기") {
                                onComplete()
                            }
                            .foregroundStyle(.secondary)
                            .frame(width: 80, height: 44)
                        } else {
                            Spacer().frame(width: 80, height: 44)
                        }

                        Spacer()

                        if currentPage < slides.count - 1 {
                            Button("다음") {
                                withAnimation { currentPage += 1 }
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 44)
                            .background(Color.fillitPrimary)
                            .clipShape(Capsule())
                        } else {
                            Button("시작하기") {
                                onComplete()
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.fillitPrimary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private struct OnboardingSlide {
    let icon: String
    var heroImageName: String? = nil
    let title: String
    let description: String
    let showSkip: Bool
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            if let imageName = slide.heroImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(color: Color.fillitPrimary.opacity(0.25), radius: 24, x: 0, y: 8)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.fillitPrimary.opacity(0.12))
                        .frame(width: 180, height: 180)
                    Image(systemName: slide.icon)
                        .font(.system(size: 72))
                        .foregroundStyle(Color.fillitPrimary)
                }
            }

            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.fillitDark)

                Text(slide.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
