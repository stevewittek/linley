import SwiftUI

struct IdeaLabView: View {
    @State private var promptIndex = 0

    private let ideas = [
        TrendIdea(
            title: "Tiny Trailer",
            category: "VIDEO",
            prompt: "Make a 15-second movie trailer starring a toy, book, or drawing.",
            icon: "movieclapper.fill"
        ),
        TrendIdea(
            title: "Three-Color Challenge",
            category: "ART",
            prompt: "Create something using only coral, white, and one surprise color.",
            icon: "paintpalette.fill"
        ),
        TrendIdea(
            title: "Before and After",
            category: "VIDEO",
            prompt: "Show a blank page, then reveal the finished drawing with a fun transition.",
            icon: "wand.and.stars"
        ),
        TrendIdea(
            title: "Finish the Story",
            category: "STORY",
            prompt: "Start with: “The loop opened, and suddenly…” Then add your own ending.",
            icon: "book.pages.fill"
        ),
        TrendIdea(
            title: "Desk Dance",
            category: "STOP MOTION",
            prompt: "Make pencils, erasers, or paper shapes dance without showing anyone's face.",
            icon: "figure.dance"
        ),
        TrendIdea(
            title: "Kindness Remix",
            category: "CHALLENGE",
            prompt: "Create a sticker, sign, or short clip that could make a friend smile.",
            icon: "heart.fill"
        )
    ]

    var body: some View {
        ZStack {
            LinleyTheme.pageGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Trendy ideas", systemImage: "wand.and.stars")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(LinleyTheme.plum)

                        Text("Fun ideas chosen for Linley—not an open social-media feed.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    featuredIdea

                    Text("More ideas to try")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LinleyTheme.plum)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        ForEach(Array(ideas.enumerated()), id: \.offset) { index, idea in
                            Button {
                                withAnimation(.snappy) {
                                    promptIndex = index
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: idea.icon)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(LinleyTheme.coralDeep)

                                    Text(idea.category)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(LinleyTheme.coralDeep)

                                    Text(idea.title)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(LinleyTheme.plum)

                                    Text(idea.prompt)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                                .padding(20)
                                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        BuilderView()
                    } label: {
                        Label("Suggest a new Idea Lab trend", systemImage: "hammer.fill")
                    }
                    .buttonStyle(LinleyPrimaryButtonStyle())
                }
                .frame(maxWidth: 980, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Idea Lab")
    }

    private var featuredIdea: some View {
        let idea = ideas[promptIndex]

        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: idea.icon)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(idea.category)
                    .font(.caption.weight(.black))
                    .foregroundStyle(LinleyTheme.coralDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white, in: Capsule())
            }

            Text(idea.title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)

            Text(idea.prompt)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.94))

            Button {
                withAnimation(.snappy) {
                    promptIndex = (promptIndex + 1) % ideas.count
                }
            } label: {
                Label("Show another idea", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(LinleyTheme.coralDeep)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinleyTheme.heroGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct TrendIdea {
    let title: String
    let category: String
    let prompt: String
    let icon: String
}

struct LinleyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(LinleyTheme.coralDeep, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        IdeaLabView()
    }
}
