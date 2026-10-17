import SwiftUI

struct WatchView: View {
    @EnvironmentObject private var store: MediaStore
    @State private var kind: Creation.Kind = .picture
    @State private var query = ""
    @State private var linkedOnly = false
    private var posts: [DemoPost] { DemoCatalog.search(query, kind: kind, linked: linkedOnly ? store.linkedCreators : nil) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A little inspiration").font(.largeTitle.bold())
                Text("Original demo art and fictional creators. Nothing here is posted by other children.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Picker("Media type", selection: $kind) {
                    Text("Pictures").tag(Creation.Kind.picture)
                    Text("Videos").tag(Creation.Kind.video)
                }.pickerStyle(.segmented)
                Toggle("Linked Creators", isOn: $linkedOnly)
                if posts.isEmpty {
                    ContentUnavailableView("No matches yet", systemImage: "magnifyingglass", description: Text(linkedOnly ? "Link a sample creator below, or try another search." : "Try a color, title or creator name."))
                } else if kind == .picture {
                    HStack(alignment: .top, spacing: 12) {
                        column(Array(posts.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)))
                        column(Array(posts.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)))
                    }
                } else {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 10) {
                            if let url = Bundle.main.url(forResource: post.resource, withExtension: "mp4") {
                                MediaPreview(url: url, kind: .video).frame(height: 260)
                            }
                            Text(post.title).font(.headline)
                            NavigationLink(post.creator) { DemoCreatorView(creator: post.creator) }
                        }
                    }
                }
                Text("Meet the sample creators").font(.title2.bold())
                ForEach(DemoCatalog.creators.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }, id: \.self) { creator in
                    NavigationLink { DemoCreatorView(creator: creator) } label: {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                            Text(creator)
                            Spacer()
                            if store.linkedCreators.contains(creator) { Image(systemName: "link") }
                            Image(systemName: "chevron.right")
                        }.padding().background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Watch")
            .searchable(text: $query, prompt: "Art, videos, sample creators")
    }
    private func column(_ items: [DemoPost]) -> some View {
        VStack(spacing: 16) {
            ForEach(items) { post in
                NavigationLink { DemoCreatorView(creator: post.creator) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(post.resource).resizable().scaledToFill().frame(height: post.height).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Text(post.title).font(.headline)
                        Text(post.creator).font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
            }
        }.frame(maxWidth: .infinity)
    }
}

struct DemoCreatorView: View {
    let creator: String
    @EnvironmentObject private var store: MediaStore
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "paintpalette.fill").font(.system(size: 60)).foregroundStyle(LinleyTheme.sky)
                Text(creator).font(.largeTitle.bold())
                Text("Fictional sample profile • Bundled art only").font(.caption).foregroundStyle(.secondary)
                Button(store.linkedCreators.contains(creator) ? "Unlink Creator" : "Link Creator") {
                    do { try store.toggleLink(creator) } catch { store.errorMessage = error.localizedDescription }
                }.buttonStyle(LinleyPrimaryButtonStyle())
                ForEach(DemoCatalog.posts.filter { $0.creator == creator }) { post in
                    Text(post.title).font(.headline)
                    if post.kind == .picture { Image(post.resource).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 20)) }
                    else if let url = Bundle.main.url(forResource: post.resource, withExtension: "mp4") { MediaPreview(url: url, kind: .video).frame(height: 260) }
                }
            }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.navigationTitle("Sample Creator")
    }
}
