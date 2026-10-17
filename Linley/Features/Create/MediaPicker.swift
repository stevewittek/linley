import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct DraftMedia: Identifiable {
    let id = UUID()
    let url: URL
    let kind: Creation.Kind
}

enum CameraAccess {
    static func request(video: Bool) async -> Bool {
        let camera = await AVCaptureDevice.requestAccess(for: .video)
        guard camera else { return false }
        return video ? await AVCaptureDevice.requestAccess(for: .audio) : true
    }
}

/// UIKit capture keeps Apple's lens switching, capture confirmation and retake controls.
struct CameraCapture: UIViewControllerRepresentable {
    let video: Bool
    var crop = false
    let onResult: (Result<DraftMedia?, Error>) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onResult) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [video ? UTType.movie.identifier : UTType.image.identifier]
        picker.cameraCaptureMode = video ? .video : .photo
        picker.videoMaximumDuration = 60
        picker.videoQuality = .typeMedium
        picker.allowsEditing = crop
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ picker: UIImagePickerController, context: Context) { }
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let result: (Result<DraftMedia?, Error>) -> Void
        init(_ result: @escaping (Result<DraftMedia?, Error>) -> Void) { self.result = result }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { result(.success(nil)) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            do {
                if let url = info[.mediaURL] as? URL {
                    let owned = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                    try FileManager.default.copyItem(at: url, to: owned)
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: owned.path)
                    result(.success(DraftMedia(url: owned, kind: .video)))
                } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.85) {
                    let owned = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    try data.write(to: owned, options: [.atomic, .completeFileProtection])
                    result(.success(DraftMedia(url: owned, kind: .picture)))
                } else { throw CocoaError(.fileReadCorruptFile) }
            } catch { result(.failure(error)) }
        }
    }
}

struct LibraryPicker: UIViewControllerRepresentable {
    var picturesOnly = false
    let onResult: (Result<DraftMedia?, Error>) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onResult) }
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = picturesOnly ? .images : .any(of: [.images, .videos])
        configuration.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ picker: PHPickerViewController, context: Context) { }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let result: (Result<DraftMedia?, Error>) -> Void
        init(_ result: @escaping (Result<DraftMedia?, Error>) -> Void) { self.result = result }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else { result(.success(nil)); return }
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    do {
                        if let error { throw error }
                        guard let url else { throw CocoaError(.fileReadUnknown) }
                        let owned = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
                        try FileManager.default.copyItem(at: url, to: owned)
                        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: owned.path)
                        DispatchQueue.main.async { self.result(.success(DraftMedia(url: owned, kind: .video))) }
                    } catch { DispatchQueue.main.async { self.result(.failure(error)) } }
                }
            } else {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    do {
                        if let error { throw error }
                        guard let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.85) else { throw CocoaError(.fileReadCorruptFile) }
                        let owned = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                        try data.write(to: owned, options: [.atomic, .completeFileProtection])
                        DispatchQueue.main.async { self.result(.success(DraftMedia(url: owned, kind: .picture))) }
                    } catch { DispatchQueue.main.async { self.result(.failure(error)) } }
                }
            }
        }
    }
}
