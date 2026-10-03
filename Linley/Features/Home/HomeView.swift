import SwiftUI

struct HomeView: View {
    @AppStorage("linley.profile.nickname") private var nickname = "Creator"

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 18)
    ]

    var body: some View {
        ZStack {
            LinleyTheme.pageGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    hero

                    Text("What do you want to do today?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LinleyTheme.plum)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                        FeatureCard(
                            icon: "video.fill",
                            title: "Make a video",
                            detail: "Tap the coral plus button to record a short creative clip. Nothing is posted or uploaded.",
                            color: LinleyTheme.coral
                        )
                        FeatureCard(
                            icon: "wand.and.stars",
                            title: "Find a trendy idea",
                            detail: "The Idea Lab has safe, parent-approved prompts for videos, stories, and creative challenges.",
                            color: LinleyTheme.gold
                        )
                        FeatureCard(
                            icon: "hammer.fill",
                            title: "Help build Linley",
                            detail: "Save a feature idea for Dad to review. Ideas never change the real app automatically.",
                            color: LinleyTheme.mint
                        )
                    }
                }
                .frame(maxWidth: 980, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            LinleyMark(size: 66)
            LinleyWordmark()
            Spacer()
            Text(LinleyCopy.version)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LinleyTheme.plum.opacity(0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.75), in: Capsule())
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Image(systemName: "sparkles")
                    .font(.title.weight(.bold))
                    .foregroundStyle(LinleyTheme.gold)
                Spacer()
                Circle()
                    .fill(LinleyTheme.coral.opacity(0.85))
                    .frame(width: 76, height: 76)
                    .overlay {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                    }
            }

            Text("Hi, \(nickname)!")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(LinleyCopy.tagline)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.92))
                .frame(maxWidth: 680, alignment: .leading)

            NavigationLink {
                IdeaLabView()
            } label: {
                Label("Open the Idea Lab", systemImage: "arrow.right")
                    .font(.headline)
                    .foregroundStyle(LinleyTheme.plum)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(LinleyTheme.gold, in: Capsule())
            }
            .accessibilityHint("Opens safe, curated creative prompts")
        }
        .padding(28)
        .background(LinleyTheme.heroGradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 28)
                .frame(width: 180, height: 180)
                .offset(x: 42, y: 58)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: LinleyTheme.plum.opacity(0.18), radius: 24, y: 12)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
