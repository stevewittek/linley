import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: MediaStore
    @AppStorage("linley.profile.nickname") private var nickname = ""
    @AppStorage("linley.profile.avatar") private var avatar = "sparkles"
    @State private var editor = false
    @State private var library = false
    @State private var camera = false
    @State private var pendingDraft: DraftMedia?
    @State private var cropDraft: DraftMedia?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Group {
                    if let data = store.profileData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: avatar).font(.system(size: 60)).foregroundStyle(LinleyTheme.coralDeep)
                    }
                }.frame(width: 140, height: 140).background(LinleyTheme.sky.opacity(0.2)).clipShape(Circle())
                    .id(store.profileRevision)
                Text(nickname.isEmpty ? "Your creative space" : nickname).font(.largeTitle.bold())
                Label("Private on this device", systemImage: "lock.shield.fill")
                Button("Edit nickname and avatar") { editor = true }.buttonStyle(.bordered)
                Button("Choose profile photo") { library = true }.buttonStyle(LinleyPrimaryButtonStyle())
                Button("Take profile photo") {
                    Task {
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { error = "A physical device is needed to take a profile photo."; return }
                        guard await CameraAccess.request(video: false) else { error = "Enable camera access in Settings or choose a photo instead."; return }
                        camera = true
                    }
                }.buttonStyle(.bordered)
                if store.profileData != nil {
                    Button("Remove profile photo", role: .destructive) {
                        do { try store.setProfile(nil) } catch { self.error = error.localizedDescription }
                    }
                }
                Text("Use a nickname, not your full name. Your photo is never uploaded or shown to sample creators.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: 650).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Profile")
            .sheet(isPresented: $editor) { ProfileSetupView(canCancel: true) { editor = false } }
            .sheet(isPresented: $library, onDismiss: presentCrop) {
                LibraryPicker(picturesOnly: true) { result in
                    library = false
                    switch result {
                    case .success(let draft): pendingDraft = draft
                    case .failure(let failure): error = failure.localizedDescription
                    }
                }
            }
            .fullScreenCover(isPresented: $camera, onDismiss: presentCrop) {
                CameraCapture(video: false) { result in
                    camera = false
                    switch result {
                    case .success(let draft): pendingDraft = draft
                    case .failure(let failure): error = failure.localizedDescription
                    }
                }
                    .ignoresSafeArea()
            }
            .sheet(item: $cropDraft, onDismiss: { cropDraft = nil }) { draft in
                ProfileCropView(draft: draft) { data in
                    do { if let data { try store.setProfile(data) }; try? FileManager.default.removeItem(at: draft.url); cropDraft = nil }
                    catch { self.error = error.localizedDescription }
                }
            }
            .alert("Profile photo", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
    }
    private func presentCrop() {
        cropDraft = pendingDraft
        pendingDraft = nil
    }
}

/// Explicit square crop with adjustable zoom and position; JPEG re-encoding drops metadata.
struct ProfileCropView: View {
    let draft: DraftMedia
    var title = "Crop profile photo"
    let onFinished: (Data?) -> Void
    @State private var zoom = 1.0
    @State private var x = 0.5
    @State private var y = 0.5
    private var cropped: UIImage? {
        guard let image = UIImage(contentsOfFile: draft.url.path), let cg = image.cgImage else { return nil }
        let side = CGFloat(min(cg.width, cg.height)) / zoom
        let rect = CGRect(x: (CGFloat(cg.width) - side) * x, y: (CGFloat(cg.height) - side) * y, width: side, height: side)
        guard let crop = cg.cropping(to: rect) else { return nil }
        let result = UIImage(cgImage: crop, scale: image.scale, orientation: image.imageOrientation)
        return UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512)).image { _ in
            result.draw(in: CGRect(x: 0, y: 0, width: 512, height: 512))
        }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let cropped { Image(uiImage: cropped).resizable().scaledToFit().frame(maxHeight: 300).clipShape(Circle()) }
                Text("Zoom"); Slider(value: $zoom, in: 1...3).accessibilityLabel("Crop zoom")
                Text("Horizontal position"); Slider(value: $x).accessibilityLabel("Horizontal crop position")
                Text("Vertical position"); Slider(value: $y).accessibilityLabel("Vertical crop position")
                Button("Use photo") { onFinished(cropped?.jpegData(compressionQuality: 0.85)) }
                    .buttonStyle(LinleyPrimaryButtonStyle()).disabled(cropped == nil)
            }.padding(24).navigationTitle(title)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onFinished(nil) } } }
                .onDisappear { try? FileManager.default.removeItem(at: draft.url) }
        }
    }
}
