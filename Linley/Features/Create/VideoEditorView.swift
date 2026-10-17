import SwiftUI
import UIKit

struct VideoEditorView: UIViewControllerRepresentable {
    let videoURL: URL
    let maximumDuration: TimeInterval
    let onFinished: (URL) -> Void
    let onCancel: () -> Void
    let onFailed: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onFinished: onFinished,
            onCancel: onCancel,
            onFailed: onFailed
        )
    }

    func makeUIViewController(context: Context) -> UIVideoEditorController {
        let editor = UIVideoEditorController()
        editor.videoPath = videoURL.path
        editor.videoMaximumDuration = maximumDuration
        editor.videoQuality = .typeMedium
        editor.delegate = context.coordinator
        return editor
    }

    func updateUIViewController(_ uiViewController: UIVideoEditorController, context: Context) {
        uiViewController.videoMaximumDuration = maximumDuration
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
        private let onFinished: (URL) -> Void
        private let onCancel: () -> Void
        private let onFailed: (String) -> Void

        init(
            onFinished: @escaping (URL) -> Void,
            onCancel: @escaping () -> Void,
            onFailed: @escaping (String) -> Void
        ) {
            self.onFinished = onFinished
            self.onCancel = onCancel
            self.onFailed = onFailed
        }

        func videoEditorController(
            _ editor: UIVideoEditorController,
            didSaveEditedVideoToPath editedVideoPath: String
        ) {
            onFinished(URL(fileURLWithPath: editedVideoPath))
        }

        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
            onCancel()
        }

        func videoEditorController(
            _ editor: UIVideoEditorController,
            didFailWithError error: Error
        ) {
            onFailed(error.localizedDescription)
        }
    }
}
