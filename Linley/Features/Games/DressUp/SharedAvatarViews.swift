import SwiftUI

/// Shared avatar components read the same protected library as Style Studio.
/// Keeping a reference to the selected saved look means removing face photos also updates every game.
struct AvatarPortrait: View {
    let look: DressUpLook
    var body: some View {
        GeometryReader { geo in
            DressUpCanvas(look:look,title:"",showsLabels:false)
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
    @State private var notice: String?
    private var introduction: some View {
        VStack(alignment:.leading,spacing:20) {
            StyleStoreRecoveryView()
            Text("Your style comes along").font(.title.bold())
            Text("Your saved look joins every game. Choose an avatar, then try a reaction.").font(.subheadline)
            avatarMenu
            if let avatar=studio.selectedAvatar, let look=studio.gameLook(ownsStyle:game.ownsStyle) {
                AvatarReactionStudio(look:look,title:avatar.title)
            }
            if studio.looks.isEmpty {
                ContentUnavailableView("Your first avatar",systemImage:"person.crop.circle.badge.plus",description:Text("Open Style Studio, choose an outfit and name your avatar, then tap Save & use avatar. Your existing game hero is ready until then."))
            }
        }
    }
    private var avatarMenu: some View {
        Menu {
            ForEach(studio.looks) { avatar in
                Button(avatar.title) {
                    do {try studio.selectAvatar(avatar.id)} catch {notice="Your avatar couldn’t change."}
                }
            }
            Button("Original game hero") {
                do {try studio.selectAvatar(nil)} catch {notice="Your character couldn’t change."}
            }
        } label: {
            Label(studio.selectedAvatar?.title ?? "Choose avatar",systemImage:"person.crop.circle.badge.checkmark")
                .font(.headline).frame(maxWidth:.infinity,alignment:.leading).padding(12)
                .background(.white,in:RoundedRectangle(cornerRadius:14))
        }.accessibilityIdentifier("avatarQuickSelector")
    }
    private func avatarRow(_ avatar: SavedStyle) -> some View {
        Button {
            do {try studio.selectAvatar(avatar.id)} catch {notice="Your avatar couldn't change. Your previous character is kept."}
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
                    do {try studio.selectAvatar(nil)} catch {notice="Your character couldn't change."}
                }.buttonStyle(.bordered)
            }
            NavigationLink {DressUpView()} label:{Label("Create or edit in Style Studio",systemImage:"tshirt.fill")}
                .buttonStyle(.borderedProminent)
            Text("Earn Linley Coins in any game to unlock more wardrobe styles. Your characters and photos stay on this device.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth:620).frame(maxWidth:.infinity)
    }
    var body: some View {
        ScrollView {libraryContent}
            .background(LinleyTheme.pageGradient).foregroundStyle(LinleyTheme.plum).preferredColorScheme(.light)
            .navigationTitle("My avatars").navigationBarTitleDisplayMode(.inline)
            .toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}}}
            .alert("My avatars",isPresented:Binding(get:{notice != nil},set:{if !$0 {notice=nil}})) {Button("OK") {notice=nil}} message:{Text(notice ?? "")}
    }
    private func safeLook(_ source: DressUpLook) -> DressUpLook {
        var look=source
        if !game.ownsStyle(look.outfit) {look.outfit="lavender"}
        if !game.ownsStyle(look.hair) {look.hair="bob"}
        if !game.ownsStyle(look.bag) {look.bag="simple"}
        return look
    }
}

struct StyleStoreRecoveryView: View {
    @EnvironmentObject private var studio: DressUpStore
    @State private var confirmingReset=false
    @State private var failure: String?
    var body: some View {
        Group {
            if studio.isLoading {ProgressView("Opening your avatars…")}
            else if !studio.healthy {
                VStack(alignment:.leading,spacing:10) {
                    Text("Your saved studio couldn’t open").font(.headline)
                    Text("The original file is kept. You can reset this unreadable studio to remove its saved avatars and face photos and start again.").font(.caption)
                    Button("Reset unreadable studio",role:.destructive) {confirmingReset=true}
                    if let failure {Text(failure).font(.caption)}
                }.padding().background(.white,in:RoundedRectangle(cornerRadius:16))
            }
        }.confirmationDialog("Reset unreadable Style Studio?",isPresented:$confirmingReset,titleVisibility:.visible) {
            Button("Delete saved studio and start again",role:.destructive) {
                do {try studio.resetUnreadable()} catch {failure="The studio couldn’t reset. Your file was kept."}
            }
            Button("Keep the original file",role:.cancel) {}
        } message:{Text("This permanently deletes the unreadable studio’s editable looks and face copies. Your game coins and pictures in My Stuff or Photos stay separate.")}
    }
}
