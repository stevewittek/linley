import SwiftUI

struct RootTabView: View {
    @State private var showingCreator = false

    var body: some View {
        NavigationStack {
            HomeView()
            .safeAreaInset(edge: .bottom) {
                HStack {
                    NavigationLink { ProfileView() } label: {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .frame(maxWidth: .infinity)
                    Button { showingCreator = true } label: { LinleyMark(size: 76) }
                        .accessibilityLabel("L, open camera")
                        .accessibilityIdentifier("createCamera")
                        .buttonStyle(.plain)
                    NavigationLink { ParentCenterView() } label: {
                        Label("Parent", systemImage: "lock.shield")
                    }
                    .frame(maxWidth: .infinity)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.regularMaterial)
            }
        }
            .fullScreenCover(isPresented: $showingCreator) { VideoCreatorView() }
    }
}
