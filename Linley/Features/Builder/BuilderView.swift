import SwiftUI

struct BuilderView: View {
    @EnvironmentObject private var store: SuggestionStore

    @State private var title = ""
    @State private var details = ""
    @State private var category = "New feature"
    @State private var savedConfirmation = false

    private let categories = ["New feature", "Design change", "Video idea", "Idea Lab", "Fix something"]

    var body: some View {
        ZStack {
            LinleyTheme.pageGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Help build Linley", systemImage: "hammer.fill")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(LinleyTheme.plum)

                        Text("Design an idea and send it to Dad for review. Saving an idea never changes the real app automatically.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Idea type", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)

                        TextField("Give your idea a short name", text: $title)
                            .font(.title3.weight(.semibold))
                            .textFieldStyle(.roundedBorder)

                        TextField("Explain what it should do and why it would be fun", text: $details, axis: .vertical)
                            .lineLimit(4...8)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            store.add(title: title, category: category, details: details)
                            title = ""
                            details = ""
                            savedConfirmation = true
                        } label: {
                            Label("Save for Dad to review", systemImage: "tray.and.arrow.down.fill")
                        }
                        .buttonStyle(LinleyPrimaryButtonStyle())
                        .disabled(!canSave)
                    }
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                    pendingIdeas
                }
                .frame(maxWidth: 820, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Builder")
        .alert("Idea saved", isPresented: $savedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("It is waiting for Dad's approval. Nothing in Linley changed automatically.")
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var pendingIdeas: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Waiting for Dad")
                .font(.title2.weight(.bold))
                .foregroundStyle(LinleyTheme.plum)

            if store.suggestions.isEmpty {
                Text("No ideas are waiting yet. Your first idea can be anything that makes Linley safer, easier, or more fun.")
                    .foregroundStyle(.secondary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinleyTheme.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                ForEach(store.suggestions) { suggestion in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(suggestion.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(LinleyTheme.plum)
                            Spacer()
                            Text("DAD REVIEW")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(LinleyTheme.coralDeep)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(LinleyTheme.coral.opacity(0.15), in: Capsule())
                        }

                        Text(suggestion.category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LinleyTheme.coralDeep)

                        Text(suggestion.details)
                            .foregroundStyle(.secondary)

                        HStack {
                            ShareLink(item: suggestion.shareText) {
                                Label("Send to Dad", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(LinleyTheme.coralDeep)

                            Spacer()

                            Button(role: .destructive) {
                                store.remove(suggestion)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        }
    }
}

#Preview {
    NavigationStack { BuilderView() }
        .environmentObject(SuggestionStore())
}
