import SwiftUI

struct ProfileView: View {
    @AppStorage("linley.profile.nickname") private var nickname = "Creator"
    @AppStorage("linley.profile.avatar") private var avatar = "sparkles"
    @State private var showingEditor = false

    var body: some View {
        ZStack {
            LinleyTheme.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: avatar)
                        .font(.system(size: 58, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 120)
                        .background(LinleyTheme.coralDeep, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                        .shadow(color: LinleyTheme.coral.opacity(0.35), radius: 18, y: 8)

                    Text(nickname)
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(LinleyTheme.plum)

                    Label("Private on this iPad", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(LinleyTheme.coralDeep)

                    Button("Edit profile") {
                        showingEditor = true
                    }
                    .buttonStyle(LinleyPrimaryButtonStyle())

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Linley safety promise", systemImage: "checkmark.shield.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(LinleyTheme.plum)

                        safetyLine("No public profile or stranger search")
                        safetyLine("No location sharing or direct messages")
                        safetyLine("Friend circles will require parent approval")
                        safetyLine("App changes always require Dad's approval")
                    }
                    .padding(24)
                    .frame(maxWidth: 650, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditor) {
            ProfileSetupView(canCancel: true) {
                showingEditor = false
            }
        }
    }

    private func safetyLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(LinleyTheme.plum)
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
