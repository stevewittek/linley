import SwiftUI
import PencilKit

struct SketchSelection: Identifiable {
    let id = UUID()
    let project: SketchSummary?
}

struct SketchbookView: View {
    @StateObject private var store = SketchStore()
    @State private var selected: SketchSelection?
    @State private var deleting: SketchSummary?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Leave a little room for imagination.").font(.title.bold())
                Text("Draw with your finger or Apple Pencil. Your editable sketches stay on this device.")
                    .foregroundStyle(.secondary)
                Button { selected = SketchSelection(project: nil) } label: { Label("New sketch", systemImage: "pencil.tip.crop.circle.badge.plus") }
                    .buttonStyle(LinleyPrimaryButtonStyle()).accessibilityIdentifier("newSketch")
                if store.projects.isEmpty {
                    ContentUnavailableView("A fresh page is waiting", systemImage: "pencil.and.outline", description: Text("Start a sketch, save it, and come back to keep drawing."))
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
                    ForEach(store.projects) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            Button { selected = SketchSelection(project: project) } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    SketchThumbnail(url: store.fileURL(project.id)).id(project.updatedAt)
                                        .frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 20))
                                    Text(project.title).font(.headline)
                                    Text(project.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                                }.foregroundStyle(LinleyTheme.plum)
                            }.buttonStyle(.plain).accessibilityIdentifier("sketch-\(project.title)")
                            Button("Delete draft", role: .destructive) { deleting = project }.font(.caption)
                        }
                    }
                }
                Text("\(store.projects.count) editable sketches • Free to draw and save").font(.footnote).foregroundStyle(.secondary)
            }.padding(22).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("My Sketchbook")
            .sheet(item: $selected) { selection in
                NavigationStack { SketchEditorView(project: selection.project).environmentObject(store) }
            }
            .confirmationDialog("Delete this editable draft? Saved pictures in My Stuff stay.", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete draft", role: .destructive) {
                    if let deleting { do { try store.delete(deleting.id) } catch { store.errorMessage = error.localizedDescription } }
                    deleting = nil
                }
            }
            .alert("Sketchbook", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK") { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
    }
}

private struct SketchThumbnail: View {
    let url: URL
    @State private var image: UIImage?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(.white)
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else { Image(systemName: "pencil.and.outline").font(.largeTitle).foregroundStyle(LinleyTheme.sky) }
        }.task(id: url) {
            let bytes = await Task.detached(priority: .utility) { try? SketchStore.read(url).preview }.value
            if !Task.isCancelled, let bytes { image = UIImage(data: bytes) }
        }
    }
}

struct SketchEditorView: View {
    let project: SketchSummary?
    @EnvironmentObject private var store: SketchStore
    @EnvironmentObject private var media: MediaStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State private var id = UUID()
    @State private var drawing = PKDrawing()
    @State private var title = ""
    @FocusState private var nameFocused: Bool
    @State private var paper = 0
    @State private var tool = 0
    @State private var ink = 0
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var action: SketchCanvasAction?
    @State private var loaded = false
    @State private var loadFailed = false
    @State private var dirty = false
    @State private var autosave: Task<Void, Never>?
    @State private var status = "Draw something to start your sketch."
    @State private var message: String?
    @State private var clear = false
    private let colors: [UIColor] = [.init(red: 0.98, green: 0.35, blue: 0.44, alpha: 1), .systemBlue, .systemOrange, .systemPurple, .systemTeal, .black]
    private let colorNames = ["Coral", "Blue", "Orange", "Purple", "Teal", "Black"]
    private let papers: [UIColor] = [.white, .init(red: 1, green: 0.94, blue: 0.96, alpha: 1), .init(red: 0.91, green: 0.96, blue: 1, alpha: 1)]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Sketch name", text: $title).textFieldStyle(.roundedBorder).accessibilityIdentifier("sketchName")
                    .focused($nameFocused).submitLabel(.done).onSubmit { nameFocused = false }
                    .onChange(of: title) { _, value in if value.count > 48 { title = String(value.prefix(48)) }; changed() }
                if loadFailed { ContentUnavailableView("This draft couldn't open", systemImage: "exclamationmark.triangle", description: Text("The saved file was kept. Return to your sketchbook and try another draft.")) }
                else {
                    GeometryReader { geo in
                        let side = max(1, geo.size.width)
                        ZStack(alignment: .topLeading) {
                            Color(uiColor: papers[paper])
                            SketchCanvas(drawing: $drawing, canUndo: $canUndo, canRedo: $canRedo,
                                         tool: tool, color: colors[ink], action: action)
                                .frame(width: 768, height: 768)
                                .scaleEffect(side / 768, anchor: .topLeading)
                                .frame(width: side, height: side, alignment: .topLeading)
                        }
                    }.aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinleyTheme.sky.opacity(0.35)))
                    Picker("Drawing tool", selection: $tool) {
                        Text("Pen").tag(0); Text("Marker").tag(1); Text("Eraser").tag(2)
                    }.pickerStyle(.segmented).accessibilityIdentifier("sketchTools")
                    HStack {
                        ForEach(colors.indices, id: \.self) { index in
                            Button { ink = index } label: {
                                Circle().fill(Color(uiColor: colors[index])).frame(width: 30, height: 30)
                                    .padding(5).overlay(Circle().stroke(ink == index ? LinleyTheme.plum : .clear, lineWidth: 2))
                            }.accessibilityLabel("\(colorNames[index]) ink")
                        }
                    }
                    Picker("Paper color", selection: $paper) {
                        Text("White").tag(0); Text("Blush").tag(1); Text("Sky").tag(2)
                    }.pickerStyle(.segmented).onChange(of: paper) { _, _ in changed() }
                    HStack {
                        Button("Undo") { action = .init(kind: .undo) }.disabled(!canUndo).accessibilityIdentifier("undoSketch")
                        Button("Redo") { action = .init(kind: .redo) }.disabled(!canRedo).accessibilityIdentifier("redoSketch")
                        Spacer()
                        Button("Clear", role: .destructive) { clear = true }.disabled(drawing.strokes.isEmpty)
                    }.buttonStyle(.bordered)
                    Text(status).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("sketchSaveStatus")
                    Button("Save picture to My Stuff") { exportPicture() }
                        .buttonStyle(LinleyPrimaryButtonStyle()).disabled(drawing.strokes.isEmpty)
                        .accessibilityIdentifier("exportSketch")
                    Text("Drafts stay editable here. Saving a picture adds a separate image to My Stuff. Drawing, saving, and reopening drafts cost no coins.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.padding(20).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }.accessibilityIdentifier("sketchEditorScroll")
            .background(LinleyTheme.pageGradient).navigationTitle("Draw & keep creating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { if loadFailed || saveDraft(showError: true) { dismiss() } }.accessibilityIdentifier("finishSketch") }
            .interactiveDismissDisabled(dirty)
            .task { loadProject() }
            .onChange(of: drawing.dataRepresentation()) { _, _ in changed() }
            .onChange(of: phase) { _, next in if next != .active { _ = saveDraft(showError: false) } }
            .onDisappear { autosave?.cancel(); _ = saveDraft(showError: false) }
            .confirmationDialog("Clear this canvas? The empty canvas will replace this draft when it saves.", isPresented: $clear, titleVisibility: .visible) {
                Button("Clear canvas", role: .destructive) { action = .init(kind: .clear) }
            }
            .alert("Sketchbook", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
    }
    private func loadProject() {
        guard !loaded else { return }
        if let project {
            do {
                let saved = try store.load(project.id)
                id = project.id; drawing = try PKDrawing(data: saved.drawing)
                title = saved.summary.title; paper = saved.summary.paper
                status = "Saved on this device."
            } catch { loadFailed = true; status = "This saved draft was kept untouched." }
        }
        // State changes from initial loading must not immediately overwrite a restored project.
        DispatchQueue.main.async { loaded = true; dirty = false }
    }
    private func changed() {
        guard loaded, !loadFailed else { return }
        dirty = true; status = "Saving draft…"
        autosave?.cancel()
        autosave = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(800)) } catch { return }
            guard !Task.isCancelled else { return }
            _ = saveDraft(showError: false)
        }
    }
    private func picture() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 768, height: 768)).image { context in
            papers[paper].setFill(); context.fill(CGRect(x: 0, y: 0, width: 768, height: 768))
            drawing.image(from: CGRect(x: 0, y: 0, width: 768, height: 768), scale: 1).draw(at: .zero)
        }
    }
    @discardableResult private func saveDraft(showError: Bool) -> Bool {
        autosave?.cancel()
        guard loaded, !loadFailed else { return false }
        guard dirty else { return true }
        if drawing.strokes.isEmpty && project == nil && !store.projects.contains(where: { $0.id == id }) {
            dirty = false; status = "Draw something to start your sketch."; return true
        }
        do {
            guard let preview = picture().jpegData(compressionQuality: 0.75) else { throw CocoaError(.fileWriteUnknown) }
            _ = try store.save(id: id, title: title, paper: paper, drawing: drawing.dataRepresentation(), preview: preview)
            dirty = false; status = "Saved on this device."; return true
        } catch {
            status = "Draft couldn't save. Keep this screen open and try again."
            if showError { message = error.localizedDescription }
            return false
        }
    }
    private func exportPicture() {
        guard saveDraft(showError: true), let bytes = picture().jpegData(compressionQuality: 0.92) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("linley-sketch-\(UUID()).jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            try bytes.write(to: url, options: [.atomic, .completeFileProtection])
            _ = try media.save(source: url, kind: .picture)
            message = "Picture saved privately to My Stuff. Your editable draft is kept in My Sketchbook."
        } catch { message = "The picture couldn't save. Your editable draft is kept. \(error.localizedDescription)" }
    }
}
