import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            LinleyTheme.pageGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    LinleyMark(size: 124)
                    LinleyWordmark()

                    Text("A creative prototype with room to grow.")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LinleyTheme.plum)

                    VStack(alignment: .leading, spacing: 18) {
                        valueRow(icon: "paintbrush.pointed.fill", title: "Creator-led", detail: "The next feature begins with an idea, a sketch, and feedback.")
                        valueRow(icon: "rectangle.3.group.fill", title: "iPad first", detail: "Layouts are designed for a big canvas and adapt to iPhone.")
                        valueRow(icon: "hand.raised.fill", title: "Safety first", detail: "No accounts, messaging, uploads, tracking, or outside services are in this prototype.")
                    }
                    .padding(24)
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                    Text("A Netherwood Data Partners project")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 680)
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About")
    }

    private func valueRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(LinleyTheme.coralDeep)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LinleyTheme.plum)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
