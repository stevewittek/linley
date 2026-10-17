import SwiftUI
import AVFoundation

struct GalleryView: View {
    @EnvironmentObject private var store: MediaStore
    @State private var selected: Creation?
    var body: some View {
        ScrollView {
            if store.creations.isEmpty {
                ContentUnavailableView("Your canvas is waiting", systemImage: "square.stack", description: Text("Tap L to capture or import your first creation."))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 16) {
                ForEach(store.creations) { item in
                    Button { selected = item } label: {
                        VStack(alignment: .leading) {
                            CreationThumbnail(url: store.url(for: item), kind: item.kind).frame(height: 170).clipped()
                            Label(item.kind == .picture ? "Picture" : "Video", systemImage: item.kind == .picture ? "photo" : "play.fill")
                                .font(.subheadline.bold())
                            Text(item.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }.foregroundStyle(LinleyTheme.plum)
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }
        .navigationTitle("My Stuff")
        .background(LinleyTheme.pageGradient)
        .sheet(item: $selected) { CreationDetail(item: $0) }
    }
}

struct CreationThumbnail: View {
    let url: URL
    let kind: Creation.Kind
    @State private var thumbnail: UIImage?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(LinleyTheme.sky.opacity(0.2))
            if let thumbnail { Image(uiImage: thumbnail).resizable().scaledToFit() }
            if kind == .video { Image(systemName: "play.circle.fill").font(.largeTitle).foregroundStyle(.white).shadow(radius: 4) }
        }
        .task(id: url) {
            if kind == .picture { thumbnail = UIImage(contentsOfFile: url.path) }
            else {
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 480, height: 480)
                if let result = try? await generator.image(at: .zero) { thumbnail = UIImage(cgImage: result.image) }
            }
        }
    }
}

struct CreationDetail: View {
    let item: Creation
    @EnvironmentObject private var store: MediaStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirm = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            MediaPreview(url: store.url(for: item), kind: item.kind).padding()
                .navigationTitle(item.kind == .picture ? "Picture" : "Video")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                    ToolbarItem(placement: .destructiveAction) { Button("Delete", role: .destructive) { confirm = true } }
                }
                .confirmationDialog("Delete this creation from this device?", isPresented: $confirm, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        do { try store.delete(item); dismiss() } catch { self.error = error.localizedDescription }
                    }
                }
                .alert("Could not delete", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK") { error = nil }
                } message: { Text(error ?? "") }
        }
    }
}
