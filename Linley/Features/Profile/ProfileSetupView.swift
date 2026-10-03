import SwiftUI

struct ProfileSetupView: View {
    @AppStorage("linley.profile.nickname") private var savedNickname = ""
    @AppStorage("linley.profile.avatar") private var savedAvatar = "sparkles"

    @State private var nickname = ""
    @State private var selectedAvatar = "sparkles"

    let canCancel: Bool
    var onFinished: (() -> Void)?

    private let avatars = [
        "sparkles", "star.fill", "heart.fill", "music.note",
        "paintpalette.fill", "camera.fill", "pawprint.fill", "rainbow"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinleyTheme.pageGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        LinleyMark(size: 92)

                        VStack(spacing: 8) {
                            Text("Make your Linley profile")
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(LinleyTheme.plum)
                                .multilineTextAlignment(.center)

                            Text("Use a nickname and an avatar. You never need to enter your full name or a photo.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nickname")
                                .font(.headline)
                                .foregroundStyle(LinleyTheme.plum)

                            TextField("What should Linley call you?", text: $nickname)
                                .textInputAutocapitalization(.words)
                                .font(.title3.weight(.semibold))
                                .padding(16)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .onChange(of: nickname) { _, newValue in
                                    if newValue.count > 18 {
                                        nickname = String(newValue.prefix(18))
                                    }
                                }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an avatar")
                                .font(.headline)
                                .foregroundStyle(LinleyTheme.plum)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 14) {
                                ForEach(avatars, id: \.self) { avatar in
                                    Button {
                                        selectedAvatar = avatar
                                    } label: {
                                        Image(systemName: avatar)
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(selectedAvatar == avatar ? .white : LinleyTheme.coralDeep)
                                            .frame(width: 64, height: 64)
                                            .background(
                                                selectedAvatar == avatar ? LinleyTheme.coralDeep : .white,
                                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            )
                                    }
                                    .accessibilityLabel("Choose \(avatar) avatar")
                                }
                            }
                        }

                        Label("This profile stays on this iPad.", systemImage: "lock.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LinleyTheme.plum)

                        Button("Start creating") {
                            savedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                            savedAvatar = selectedAvatar
                            onFinished?()
                        }
                        .buttonStyle(LinleyPrimaryButtonStyle())
                        .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .frame(maxWidth: 620)
                    .padding(28)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                if canCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onFinished?() }
                    }
                }
            }
            .onAppear {
                nickname = savedNickname
                selectedAvatar = savedAvatar
            }
        }
    }
}

#Preview {
    ProfileSetupView(canCancel: false)
}
