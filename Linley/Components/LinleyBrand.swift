import SwiftUI

struct LinleyMark: View {
    var size: CGFloat = 88

    var body: some View {
        Image("LinleyMark")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            }
            .shadow(color: LinleyTheme.plum.opacity(0.18), radius: 16, y: 8)
            .accessibilityLabel("Linley coral looping L logo")
    }
}

struct LinleyWordmark: View {
    var light = false

    var body: some View {
        HStack(spacing: 10) {
            Text("L")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .italic()
                .foregroundStyle(LinleyTheme.coral)
                .rotationEffect(.degrees(-6))

            Text("inley")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .tracking(-1.4)
                .foregroundStyle(light ? Color.white : LinleyTheme.plum)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LinleyCopy.appName)
    }
}
