import SwiftUI

enum AvatarReaction: String, CaseIterable, Identifiable {
    case greeting, celebrate, spotlight

    var id: String { rawValue }
    var title: String {
        switch self {
        case .greeting: "Hello"
        case .celebrate: "Celebrate"
        case .spotlight: "Spotlight"
        }
    }
    var symbol: String {
        switch self {
        case .greeting: "hand.raised.fill"
        case .celebrate: "sparkles"
        case .spotlight: "star.circle.fill"
        }
    }
    var caption: String {
        switch self {
        case .greeting: "A little hello, your way."
        case .celebrate: "Your look. Your winning moment."
        case .spotlight: "Step into your spotlight."
        }
    }
}

/// Three short, on-demand reactions for the existing illustrated outfit artwork.
/// These animate a complete look, so every saved outfit and private face stays together.
struct AvatarReactionStudio: View {
    let look: DressUpLook
    let title: String
    @State private var reaction: AvatarReaction = .greeting
    @State private var playToken = 0

    var body: some View {
        VStack(spacing: 14) {
            AvatarReactionPreview(look: look, title: title, reaction: reaction, playToken: playToken)
                .frame(maxWidth: 230)
            HStack(spacing: 8) {
                ForEach(AvatarReaction.allCases) { option in
                    Button {
                        reaction = option
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.symbol).font(.title3)
                            Text(option.title).font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(reaction == option ? Color.white : LinleyTheme.plum)
                        .background(reaction == option ? LinleyTheme.plum : LinleyTheme.plum.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(reaction == option ? .isSelected : [])
                    .accessibilityIdentifier("avatar-reaction-\(option.rawValue)")
                }
            }
            Button {
                playToken &+= 1
            } label: {
                Label("Play \(reaction.title)", systemImage: "play.fill")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(LinleyTheme.plum)
            .accessibilityIdentifier("avatar-reaction-play")
            Text("Short animated poses. Your avatar stays private on this device.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        #if DEBUG
        .task {
            // Explicit headless review fixture; no automatic playback in shipped builds.
            guard ProcessInfo.processInfo.arguments.contains("--quest-ui-tests"),
                  ProcessInfo.processInfo.arguments.contains("--avatar-play-review") else {return}
            reaction = .celebrate
            do {try await Task.sleep(for:.seconds(2));try Task.checkCancellation();playToken=1} catch {}
        }
        #endif
    }
}

struct AvatarReactionPreview: View {
    let look: DressUpLook
    let title: String
    let reaction: AvatarReaction
    let playToken: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = 0
    @State private var lastPlayedToken: Int?

    private struct Playback: Equatable {
        let token: Int
        let reaction: AvatarReaction
        let active: Bool
        let reduced: Bool
    }

    private var playback: Playback {
        Playback(token: playToken, reaction: reaction, active: scenePhase == .active, reduced: reduceMotion)
    }
    private var active: Bool { phase > 0 }
    private var rotation: Double {
        guard !reduceMotion else { return 0 }
        switch reaction {
        case .greeting: return phase == 1 ? -2.5 : phase == 2 ? 2 : 0
        case .celebrate: return phase == 1 ? -1.5 : phase == 2 ? 1.5 : 0
        case .spotlight: return phase == 1 ? -3 : phase == 2 ? 3 : 0
        }
    }
    private var lift: CGFloat {
        guard !reduceMotion else { return 0 }
        switch reaction {
        case .greeting: return phase == 2 ? -5 : 0
        case .celebrate: return phase == 1 ? -12 : phase == 3 ? -6 : 0
        case .spotlight: return active ? -3 : 0
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [Color(red: 0.94, green: 0.89, blue: 1), Color(red: 1, green: 0.93, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing))
                DressUpCanvas(look: look.valid ? look : DressUpLook(), title: title, poseRotation: rotation, poseLift: lift)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(12)
                ornaments
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .aspectRatio(2 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            Text(reaction.caption)
                .font(.caption.weight(.medium))
                .foregroundStyle(LinleyTheme.plum)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(active ? "Playing \(reaction.title)" : "\(reaction.title) ready")
        .task(id: playback) {
            // SwiftUI cancels the finite sequence on disappearance, a new play, or backgrounding.
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { phase = 0 }
            guard playback.active, playToken != 0, lastPlayedToken != playToken else { return }
            lastPlayedToken = playToken
            do {
                if reduceMotion {
                    phase = 1
                    try await Task.sleep(for: .milliseconds(1400))
                } else {
                    for next in [1, 2, 3] {
                        try Task.checkCancellation()
                        withAnimation(.easeInOut(duration: 0.38)) { phase = next }
                        try await Task.sleep(for: .milliseconds(480))
                    }
                }
                try Task.checkCancellation()
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { phase = 0 }
            } catch {
                // The replacement task resets immediately; no detached work or timer survives.
            }
        }
    }

    private var ornaments: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                if reaction == .spotlight {
                    Ellipse()
                        .fill(Color.white.opacity(active ? 0.5 : 0))
                        .frame(width: width * 0.75, height: height * 0.78)
                        .blur(radius: 20)
                        .blendMode(.softLight)
                        .position(x: width * 0.5, y: height * 0.48)
                }
                ForEach(0..<6, id: \.self) { index in
                    let left = index.isMultiple(of: 2)
                    Image(systemName: reaction == .greeting ? "heart.fill" : "sparkle")
                        .font(.system(size: width * (index < 2 ? 0.07 : 0.045), weight: .bold))
                        .foregroundStyle(index.isMultiple(of: 3) ? Color(red: 0.96, green: 0.65, blue: 0.35) : LinleyTheme.plum.opacity(0.7))
                        .position(x: width * (left ? 0.12 : 0.88), y: height * (0.18 + Double(index / 2) * 0.23))
                        .offset(y: active && !reduceMotion ? -8 : 0)
                        .opacity(active ? 1 : 0)
                        .scaleEffect(active ? 1 : 0.8)
                }
            }
        }
    }
}
