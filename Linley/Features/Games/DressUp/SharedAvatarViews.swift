import SwiftUI

/// Shared avatar components read the same protected library as Style Studio.
/// Keeping a reference to the selected saved look means removing face photos also updates every game.
struct AvatarPortrait: View {
    let look: DressUpLook
    var body: some View {
        GeometryReader { geo in
            DressUpCanvas(look:look,title:"")
                .frame(width:geo.size.width,height:geo.size.width*1.5)
                .scaleEffect(2.7,anchor:UnitPoint(x:0.5,y:0.22))
                .frame(width:geo.size.width,height:geo.size.height,alignment:.top)
                .clipped()
        }.clipShape(Circle()).background(.white,in:Circle())
            .overlay(Circle().stroke(LinleyTheme.plum.opacity(0.25),lineWidth:2))
            .accessibilityHidden(true)
    }
}

struct GameAvatarHero: View {
    @EnvironmentObject private var studio: DressUpStore
    @EnvironmentObject private var game: QuestStore
    var body: some View {
        if let look=studio.gameLook(ownsStyle:game.ownsStyle) {
            AvatarPortrait(look:look).accessibilityHidden(true)
        } else { QuestHeroView(hero:game.progress.hero) }
    }
}

struct AvatarPlayerCard: View {
    @EnvironmentObject private var studio: DressUpStore
    @EnvironmentObject private var game: QuestStore
    var body: some View {
        if let avatar=studio.selectedAvatar, let look=studio.gameLook(ownsStyle:game.ownsStyle) {
            HStack(spacing:12) {
                AvatarPortrait(look:look).frame(width:48,height:48)
                VStack(alignment:.leading,spacing:3) {
                    Text("Playing as").font(.caption).foregroundStyle(.secondary)
                    Text(avatar.title).font(.headline)
                }
                Spacer()
            }.accessibilityElement(children:.combine).accessibilityIdentifier("gameSelectedAvatar")
        }
    }
}

struct AvatarVictoryView: View {
    @EnvironmentObject private var studio: DressUpStore
    @EnvironmentObject private var game: QuestStore
    var body: some View {
        if let avatar=studio.selectedAvatar, let look=studio.gameLook(ownsStyle:game.ownsStyle) {
            AvatarReactionPreview(look:look,title:avatar.title,reaction:.celebrate,playToken:1)
                .frame(width:120,height:180).clipShape(RoundedRectangle(cornerRadius:18))
                .frame(maxWidth:.infinity).accessibilityIdentifier("avatarVictory")
        }
    }
}

struct AvatarLibraryCard: View {
    @EnvironmentObject private var studio: DressUpStore
    @EnvironmentObject private var game: QuestStore
    @State private var showingLibrary=false
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(spacing:14) {
                GameAvatarHero().frame(width:64,height:72)
                VStack(alignment:.leading,spacing:4) {
                    Text(studio.selectedAvatar?.title ?? "Your game character").font(.title3.bold())
                    Text(studio.selectedAvatar == nil ? "Save a Style Studio avatar to bring your look into every game." : "One saved style, ready for every game.").font(.caption)
                }
                Spacer(minLength:0)
            }
            Button(studio.looks.isEmpty ? "Meet your avatars" : "Choose avatar & reactions") {showingLibrary=true}
                .buttonStyle(.borderedProminent).accessibilityIdentifier("openAvatarLibrary")
        }.padding(18).background(.white.opacity(0.9),in:RoundedRectangle(cornerRadius:24))
            .sheet(isPresented:$showingLibrary) {NavigationStack {AvatarLibraryView()}}
    }
}

struct AvatarLibraryView: View {
    @EnvironmentObject private var studio: DressUpStore
    @EnvironmentObject private var game: QuestStore
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    private var introduction: some View {
        VStack(alignment:.leading,spacing:20) {
            Text("Your style comes along").font(.title.bold())
            Text("Choose a saved avatar for Creative Quest, Puzzle Chase and Gem Garden. Try three reactions on its little stage. Your photos and characters stay on this device.").font(.subheadline)
            if let avatar=studio.selectedAvatar, let look=studio.gameLook(ownsStyle:game.ownsStyle) {
                AvatarReactionStudio(look:look,title:avatar.title)
            }
            if studio.looks.isEmpty {
                ContentUnavailableView("Your first avatar",systemImage:"person.crop.circle.badge.plus",description:Text("Open Style Studio, choose an outfit and name your avatar, then tap Save & use avatar. Your existing game hero is ready until then."))
            }
        }
    }
    private func avatarRow(_ avatar: SavedStyle) -> some View {
        Button {
            do {try studio.selectAvatar(avatar.id)} catch {error="Your avatar couldn't change. Your previous character is kept."}
        } label: {
            HStack(spacing:12) {
                AvatarPortrait(look:safeLook(avatar.look)).frame(width:62,height:62)
                Text(avatar.title).font(.headline).multilineTextAlignment(.leading)
                Spacer()
                Image(systemName:studio.selectedAvatarID == avatar.id ? "checkmark.circle.fill" : "circle")
            }.padding(12).background(.white,in:RoundedRectangle(cornerRadius:18))
        }.buttonStyle(.plain).accessibilityLabel("Use \(avatar.title)")
            .accessibilityAddTraits(studio.selectedAvatarID == avatar.id ? .isSelected : [])
            .accessibilityIdentifier("chooseAvatar-\(avatar.id)")
    }
    private var libraryContent: some View {
        VStack(alignment:.leading,spacing:20) {
            introduction
            ForEach(studio.looks) { avatar in avatarRow(avatar) }
            if studio.selectedAvatarID != nil {
                Button("Use my original game hero") {
                    do {try studio.selectAvatar(nil)} catch {error="Your character couldn't change."}
                }.buttonStyle(.bordered)
            }
            NavigationLink {DressUpView()} label:{Label("Create or edit in Style Studio",systemImage:"tshirt.fill")}
                .buttonStyle(.borderedProminent)
            Text("Paid wardrobe items still use earned game coins. If game progress is reset, the free outfit replaces any items you no longer own; your saved artwork is kept.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth:620).frame(maxWidth:.infinity)
    }
    var body: some View {
        ScrollView {libraryContent}
            .background(LinleyTheme.pageGradient).foregroundStyle(LinleyTheme.plum).preferredColorScheme(.light)
            .navigationTitle("My avatars").navigationBarTitleDisplayMode(.inline)
            .toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}}}
            .alert("My avatars",isPresented:Binding(get:{error != nil},set:{if !$0 {error=nil}})) {Button("OK") {error=nil}} message:{Text(error ?? "")}
    }
    private func safeLook(_ source: DressUpLook) -> DressUpLook {
        var look=source
        if !game.ownsStyle(look.outfit) {look.outfit="lavender"}
        if !game.ownsStyle(look.hair) {look.hair="bob"}
        if !game.ownsStyle(look.bag) {look.bag="simple"}
        return look
    }
}
