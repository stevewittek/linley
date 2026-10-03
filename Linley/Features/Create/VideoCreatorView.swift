import AVKit
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct VideoCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval = 15
    @State private var showingCamera = false
    @State private var showingCameraUnavailable = false
    @State private var videoURL: URL?

    private let durations: [TimeInterval] = [15, 30, 60]

    var body: some View {
        NavigationStack {
            ZStack {
                LinleyTheme.pageGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 108, height: 108)
                            .background(LinleyTheme.coralDeep, in: RoundedRectangle(cornerRadius: 34, style: .continuous))

                        Text("Make a Linley video")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(LinleyTheme.plum)
                            .multilineTextAlignment(.center)

                        Text("Record something creative. This prototype does not post or upload your video.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Picker("Maximum length", selection: $selectedDuration) {
                            ForEach(durations, id: \.self) { duration in
                                Text("\(Int(duration)) sec").tag(duration)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let videoURL {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(minHeight: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                            Button("Record another") {
                                startCamera()
                            }
                            .buttonStyle(LinleyPrimaryButtonStyle())
                        } else {
                            Button {
                                startCamera()
                            } label: {
                                Label("Open camera", systemImage: "camera.fill")
                            }
                            .buttonStyle(LinleyPrimaryButtonStyle())
                        }

                        Label("Ask a parent before sharing a video with anyone.", systemImage: "checkmark.shield.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LinleyTheme.plum)
                    }
                    .frame(maxWidth: 720)
                    .padding(28)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraRecorder(maximumDuration: selectedDuration) { url in
                    videoURL = url
                }
                .ignoresSafeArea()
            }
            .alert("Camera unavailable", isPresented: $showingCameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Try Linley on a physical iPad or iPhone with a camera.")
            }
        }
    }

    private func startCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showingCameraUnavailable = true
            return
        }
        showingCamera = true
    }
}

private struct CameraRecorder: UIViewControllerRepresentable {
    let maximumDuration: TimeInterval
    let onFinished: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoMaximumDuration = maximumDuration
        picker.videoQuality = .typeMedium
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        uiViewController.videoMaximumDuration = maximumDuration
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onFinished: (URL) -> Void

        init(onFinished: @escaping (URL) -> Void) {
            self.onFinished = onFinished
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                onFinished(url)
            }
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    VideoCreatorView()
}
