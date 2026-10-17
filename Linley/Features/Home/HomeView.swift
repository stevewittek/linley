import SwiftUI

struct HomeView: View {
    @AppStorage("linley.profile.nickname") private var nickname = ""

    var body: some View {
        ZStack {
            LinleyTheme.pageGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 12) {
                        NavigationLink { WatchView() } label: {
                            destination("Watch", icon: "play.rectangle.fill", color: LinleyTheme.sky)
                        }
                        NavigationLink { GalleryView() } label: {
                            destination("My Stuff", icon: "square.stack.fill", color: LinleyTheme.orange)
                        }
                    }
                    LinleyWordmark()
                    CoinBalanceView()
                    HStack(spacing: 20) {
                        NavigationLink { CreativeStudioView() } label: {
                            Label("Image Maker", systemImage: "paintpalette.fill")
                        }
                        NavigationLink { CreativeShopView() } label: {
                            Label("Creative Shop", systemImage: "sparkles")
                        }
                    }.font(.headline).buttonStyle(.bordered)
                    NavigationLink { SketchbookView() } label: {
                        Label("My Sketchbook", systemImage: "pencil.and.outline")
                    }.font(.headline).buttonStyle(.bordered).accessibilityIdentifier("openSketchbook")
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: "sparkles").font(.largeTitle)
                        Text(nickname.isEmpty ? "Make something\nonly you can make." : "Your next creation,\n\(nickname).")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        Text("Little moments. Big imagination.")
                            .font(.title3)
                        HStack {
                            Label("Your space to create", systemImage: "camera.aperture")
                            Spacer()
                            Image(systemName: "scribble.variable").font(.largeTitle)
                        }.font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(26).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinleyTheme.heroGradient, in: RoundedRectangle(cornerRadius: 30))
                    Label("Made here. Kept here.", systemImage: "lock.fill")
                        .font(.headline).foregroundStyle(LinleyTheme.plum)
                    Text("Tap L to take a photo or make a video. Your creations stay private on this device.")
                        .foregroundStyle(.secondary)
                }
                .padding(22).frame(maxWidth: 900).frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Home").navigationBarTitleDisplayMode(.inline)
    }

    private func destination(_ title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon).font(.title)
            Text(title).font(.title2.bold())
        }
        .foregroundStyle(LinleyTheme.plum).padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.27), in: RoundedRectangle(cornerRadius: 24))
    }
}
