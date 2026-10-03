import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(LinleyTheme.plum)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.55), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(LinleyTheme.plum)

            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(20)
        .background(.background.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(color.opacity(0.45), lineWidth: 1)
        }
    }
}
