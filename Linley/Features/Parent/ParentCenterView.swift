import SwiftUI
import LocalAuthentication

struct ParentCenterView: View {
    @Environment(\.scenePhase) private var phase
    @State private var unlocked = false
    @State private var authenticating = false
    @State private var message: String?
    @State private var context: LAContext?
    @State private var active = false
    var body: some View {
        Form {
            Section {
                Text("A private space for grown-ups").font(.title2.bold())
                Text("This prototype uses the device owner's Face ID, Touch ID or device passcode. A child who knows the device passcode can also unlock it. This does not verify an adult's identity or establish parental consent.")
            }
            if unlocked {
                Section("Feature permissions") {
                    permission("Create and save on this device", allowed: FeaturePolicy.localCreation)
                    permission("Cloud storage", allowed: FeaturePolicy.cloudStorage)
                    permission("Public posting", allowed: FeaturePolicy.publicPosting)
                    permission("Messages and communication", allowed: FeaturePolicy.communication)
                }
                Section("Privacy") {
                    Text("Photos, videos and profile photos stay in private app storage, excluded from cloud backup. Deleting the app removes its local creations. There is no account, advertising or analytics service.")
                    Text("Sample creator links only filter bundled demo content. They do not connect children to people.")
                }
                Section("Before any connected features") {
                    Text("Separate adult and child identities, verified parental authorization, revocation and deletion workflows, moderation and approval records require a production service and legal review. All connected features remain disabled in this build.")
                }
                Button("Lock Parent Center") { lock() }
            } else {
                Section {
                    Button(authenticating ? "Authenticating…" : "Unlock Parent Center") { Task { await authenticate() } }.disabled(authenticating)
                    if let message { Text(message).foregroundStyle(.secondary) }
                }
            }
        }.navigationTitle("Parent Center")
            .onAppear { active = true }
            .onDisappear { active = false; lock() }
            .onChange(of: phase) { _, next in
                // Authentication itself can make the app inactive; background always invalidates it.
                if next == .background { lock() }
            }
    }
    private func permission(_ title: String, allowed: Bool) -> some View {
        HStack {
            Label(title, systemImage: allowed ? "checkmark.circle.fill" : "lock.fill")
            Spacer()
            Text(allowed ? "Allowed" : "Disabled").font(.caption.bold())
        }
    }
    private func lock() {
        context?.invalidate(); context = nil
        unlocked = false; authenticating = false
    }
    @MainActor private func authenticate() async {
        let attempt = LAContext()
        var error: NSError?
        guard attempt.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            message = "Device authentication is unavailable. Set a device passcode in Settings. Parent Center stays locked."
            return
        }
        context = attempt; authenticating = true
        do {
            let success = try await attempt.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Open Linley's Parent Center")
            guard context === attempt, active, phase != .background else { return }
            unlocked = success
            authenticating = false
        } catch {
            guard context === attempt else { return }
            unlocked = false; authenticating = false; message = "Authentication was not completed. Parent Center stays locked."
        }
    }
}
