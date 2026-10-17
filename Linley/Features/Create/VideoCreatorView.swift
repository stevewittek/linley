import AVKit
import SwiftUI

struct VideoCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MediaStore
    @State private var videoMode = false
    @State private var camera = false
    @State private var library = false
    @State private var editor = false
    @State private var draft: DraftMedia?
    @State private var error: String?
    @State private var busy = false
    @State private var started = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Capture mode", selection: $videoMode) {
                        Text("Photo").tag(false)
                        Text("Video").tag(true)
                    }.pickerStyle(.segmented)
                    if let draft {
                        MediaPreview(url: draft.url, kind: draft.kind).frame(height: 360)
                        Button("Save to My Stuff") {
                            do { try store.save(source: draft.url, kind: draft.kind); cleanup(); dismiss() }
                            catch { self.error = error.localizedDescription }
                        }.buttonStyle(LinleyPrimaryButtonStyle())
                        if draft.kind == .video && UIVideoEditorController.canEditVideo(atPath: draft.url.path) {
                            Button("Edit Video") { editor = true }.buttonStyle(.bordered)
                        }
                        Button("Retake") { cleanup(); Task { await openCamera() } }.buttonStyle(.bordered)
                        Button("Discard", role: .destructive) { cleanup() }
                    } else {
                        Image(systemName: videoMode ? "video.fill" : "camera.fill")
                            .font(.system(size: 72)).foregroundStyle(LinleyTheme.coralDeep).padding(32)
                        Text("Your next great creation").font(.title.bold())
                        Text("Choose Photo or Video, then open the camera. Use the camera's flip button for the other lens.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button(videoMode ? "Record video" : "Take photo") { Task { await openCamera() } }
                            .buttonStyle(LinleyPrimaryButtonStyle()).disabled(busy)
                        Button { library = true } label: { Label("Import photo or video", systemImage: "photo.on.rectangle") }
                            .buttonStyle(.bordered)
                    }
                    Label("Private on this device", systemImage: "lock.fill").font(.footnote)
                }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }
            .background(LinleyTheme.pageGradient)
            .navigationTitle("Create")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cleanup(); dismiss() } } }
            .fullScreenCover(isPresented: $camera) {
                CameraCapture(video: videoMode) { result in
                    camera = false
                    switch result {
                    case .success(let item): draft = item
                    case .failure(let failure): error = failure.localizedDescription
                    }
                }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $library) {
                LibraryPicker { result in
                    library = false
                    switch result {
                    case .success(let item): draft = item
                    case .failure(let failure): error = failure.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $editor) {
                if let draft {
                    VideoEditorView(videoURL: draft.url, maximumDuration: 60) { url in
                        do {
                            let owned = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                            try FileManager.default.copyItem(at: url, to: owned)
                            cleanup()
                            self.draft = DraftMedia(url: owned, kind: .video)
                            editor = false
                        } catch { editor = false; self.error = error.localizedDescription }
                    } onCancel: { editor = false } onFailed: { error = $0; editor = false }
                }
            }
            .alert("Could not finish", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
            .task {
                guard !started else { return }
                started = true
                await openCamera()
            }
        }
    }
    @MainActor private func openCamera() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "This device has no camera. You can still import a photo or video. Camera capture needs a physical iPhone or iPad."
            return
        }
        guard await CameraAccess.request(video: videoMode) else {
            error = "Camera access is required to capture. Video also needs microphone access. You can change access in Settings or import instead."
            return
        }
        camera = true
    }
    private func cleanup() {
        if let draft { try? FileManager.default.removeItem(at: draft.url) }
        draft = nil
    }
}

struct MediaPreview: View {
    let url: URL
    let kind: Creation.Kind
    @State private var player: AVPlayer?
    var body: some View {
        Group {
            if kind == .video {
                VideoPlayer(player: player).onAppear { player = AVPlayer(url: url) }
                    .onDisappear { player?.pause(); player = nil }
                    .id(url)
            } else if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ContentUnavailableView("Media unavailable", systemImage: "photo.badge.exclamationmark")
            }
        }.clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
