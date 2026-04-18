import SwiftUI

struct CreateRoomView: View {
    @State private var viewModel = CreateRoomViewModel()
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Template selection
                TemplatePickerSection(viewModel: viewModel)

                SectionDivider()

                // Mode
                ModeSection(viewModel: viewModel)

                SectionDivider()

                // Nickname
                NicknameSection(viewModel: viewModel)

                SectionDivider()

                // Keyword
                KeywordSection(viewModel: viewModel)

                SectionDivider()

                // Deadline
                DeadlineSection(viewModel: viewModel)

                // Create button
                Button {
                    Task { await viewModel.createRoom(router: router) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("방 만들기").font(.body.weight(.semibold))
                    }
                }
                .primaryButton()
                .disabled(!viewModel.canCreate || viewModel.isLoading)
                .opacity(!viewModel.canCreate ? 0.5 : 1)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("방 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadTemplates() }
        .loadingOverlay(viewModel.isLoading)
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Subviews

private struct TemplatePickerSection: View {
    @Bindable var viewModel: CreateRoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "템플릿 선택", icon: "square.grid.2x2")

            if viewModel.isLoadingTemplates {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.templates) { template in
                            TemplateThumb(
                                template: template,
                                isSelected: viewModel.selectedTemplateId == template.id
                            ) {
                                viewModel.selectedTemplateId = template.id
                                if viewModel.participantLimit > template.slots.count {
                                    viewModel.participantLimit = template.slots.count
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct TemplateThumb: View {
    let template: Template
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.fillitPrimary : Color.clear, lineWidth: 2)
                    )
                GeometryReader { geo in
                    let scale = min(geo.size.width, geo.size.height)
                    ForEach(template.slots) { slot in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? Color.fillitPrimary.opacity(0.6) : Color.gray.opacity(0.4))
                            .frame(
                                width: slot.w / 100 * scale - 2,
                                height: slot.h / 100 * scale - 2
                            )
                            .position(
                                x: slot.x / 100 * scale + slot.w / 100 * scale / 2,
                                y: slot.y / 100 * scale + slot.h / 100 * scale / 2
                            )
                    }
                }
                .frame(width: 64, height: 64)
            }
            Text(template.name)
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.fillitPrimary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 80)
        .onTapGesture(perform: onTap)
    }
}

private struct ModeSection: View {
    @Bindable var viewModel: CreateRoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "촬영 모드", icon: "person.2")

            HStack(spacing: 12) {
                ModeButton(
                    title: "혼자 찍기",
                    subtitle: "내가 모든 슬롯 채우기",
                    icon: "person.fill",
                    isSelected: viewModel.mode == .solo
                ) { viewModel.mode = .solo }

                ModeButton(
                    title: "다같이 찍기",
                    subtitle: "친구들과 함께 채우기",
                    icon: "person.2.fill",
                    isSelected: viewModel.mode == .multi
                ) { viewModel.mode = .multi }
            }
            .padding(.horizontal)

            if viewModel.mode == .multi {
                VStack(alignment: .leading, spacing: 8) {
                    Text("참여 인원 (\(viewModel.participantLimit)명)")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(2...max(2, viewModel.maxParticipants), id: \.self) { count in
                                Button("\(count)명") {
                                    viewModel.participantLimit = count
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(viewModel.participantLimit == count ? .white : Color.fillitPrimary)
                                .frame(width: 52, height: 36)
                                .background(viewModel.participantLimit == count ? Color.fillitPrimary : Color.fillitPrimary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

private struct ModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.fillitPrimary : .secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.fillitPrimary : .primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(isSelected ? Color.fillitPrimary.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.fillitPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct NicknameSection: View {
    @Bindable var viewModel: CreateRoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "닉네임", icon: "person.badge.key")
            TextField("닉네임을 입력하세요 (최대 30자)", text: $viewModel.nickname)
                .textFieldStyle(FillitTextFieldStyle())
                .onChange(of: viewModel.nickname) { _, v in
                    viewModel.nickname = String(v.prefix(30))
                }
                .padding(.horizontal)
        }
    }
}

private struct KeywordSection: View {
    @Bindable var viewModel: CreateRoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "투표 키워드 (선택)", icon: "tag")
            TextField("예: #여행 #생일 #모임", text: $viewModel.keyword)
                .textFieldStyle(FillitTextFieldStyle())
                .onChange(of: viewModel.keyword) { _, v in
                    viewModel.keyword = String(v.prefix(60))
                }
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.keywordPresets, id: \.self) { preset in
                        Button(preset) {
                            viewModel.keyword = preset
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(viewModel.keyword == preset ? .white : Color.fillitPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.keyword == preset ? Color.fillitPrimary : Color.fillitPrimary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct DeadlineSection: View {
    @Bindable var viewModel: CreateRoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "업로드 마감 (선택)", icon: "clock")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DeadlinePreset.allCases, id: \.self) { preset in
                        Button(preset.rawValue) {
                            viewModel.deadlinePreset = preset
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(viewModel.deadlinePreset == preset ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.deadlinePreset == preset ? Color.fillitPrimary : Color(uiColor: .secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.deadlinePreset == .custom {
                DatePicker(
                    "마감 시간",
                    selection: $viewModel.customDeadline,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .padding(.horizontal)
    }
}

private struct SectionDivider: View {
    var body: some View {
        Divider().padding(.horizontal)
    }
}
