import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 10) {
                    Image("ic_fillit")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.fillitPrimary.opacity(0.2), radius: 12, x: 0, y: 4)
                    Text("Fillit")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.fillitPrimary)
                    Text("소중한 순간들을 함께 채워보세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // Join room
                VStack(spacing: 14) {
                    Text("방 코드로 참여하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    @Bindable var vm = viewModel
                    TextField("방 코드 6자리 입력", text: $vm.roomCode)
                        .textFieldStyle(FillitTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.roomCode) { _, v in
                            viewModel.roomCode = String(v.prefix(6).uppercased())
                        }

                    Button {
                        viewModel.joinRoom(router: router)
                    } label: {
                        Text("참여하기")
                            .font(.body.weight(.semibold))
                    }
                    .primaryButton()
                    .disabled(viewModel.roomCode.count != 6)
                    .opacity(viewModel.roomCode.count != 6 ? 0.5 : 1)
                }
                .padding(.horizontal)

                HStack {
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    Text("또는").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 8)
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                }
                .padding(.horizontal)

                // Create room
                Button {
                    router.navigate(to: .createRoom)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("새 방 만들기")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.fillitPrimary.opacity(0.12))
                    .foregroundStyle(Color.fillitPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Use cases
                UseCaseSectionView()
            }
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct UseCaseSectionView: View {
    private let cases: [(String, String, String)] = [
        ("airplane", "여행", "함께한 여행 기록"),
        ("birthday.cake", "생일", "특별한 날의 추억"),
        ("figure.2", "모임", "소중한 사람들과"),
        ("graduationcap", "졸업", "영원한 순간"),
        ("music.note", "페스티벌", "뜨거운 현장 속"),
        ("fork.knife", "맛집", "맛있는 기억들")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이런 상황에서 활용해보세요")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cases, id: \.1) { icon, title, subtitle in
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(Color.fillitPrimary)
                                .frame(width: 56, height: 56)
                                .background(Color.fillitPrimary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 90)
                        .padding(12)
                        .fillitCard()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
