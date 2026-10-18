import SwiftUI
import Photos
import AVFoundation

struct DressUpView: View {
    @EnvironmentObject private var game: QuestStore
    @EnvironmentObject private var media: MediaStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audio = QuestAudio()
    @State private var soundSettings = false
    @State private var draftSaveTask: Task<Void, Never>?
    @EnvironmentObject private var studio: DressUpStore
    @State private var look = DressUpLook()
    @State private var title = "My encore look"
    @State private var tab = 0
    @State private var brief = 0
    @State private var pendingPurchase: String?
    @State private var deleteID: UUID?
    @State private var clearPhotos = false
    @State private var library = false
    @State private var camera = false
    @State private var pendingPhoto: DraftMedia?
    @State private var cropPhoto: DraftMedia?
    @State private var activeCropURL: URL?
    @State private var notice: String?
    @State private var faceZoom = false
    @State private var moveMode = false
    @State private var selectedLayer = "hair"
    @GestureState private var dragTranslation = CGSize.zero
    private let tabs = ["Outfits", "Hair", "Face", "Makeup", "Extras", "Scene", "Missions", "Save"]
    private let tabIcons = ["tshirt","comb","person.crop.circle","paintbrush.pointed","bag","sparkles","star","heart.text.square"]
    private let layerNames = ["hair":"Hair","face":"Face","bag":"Bag","glasses":"Glasses","accessory":"Clip / headphones","makeup":"Makeup","ears":"Animal ears"]
    private var editorLayout: some View {
        GeometryReader { geo in
            if geo.size.width > 740 {
                HStack(alignment:.top,spacing:22) {
                    ScrollView {
                        VStack(spacing:12) {
                            CoinBalanceView()
                            editingStage(height:min(geo.size.height*0.62,(min(geo.size.width*0.44,440)-150)*1.5))
                            if moveMode {movementControls}
                        }
                    }.frame(width:min(geo.size.width*0.44,440))
                    VStack(spacing:12) { categoryBar; ScrollView { VStack {StyleStoreRecoveryView();controls}.padding(.bottom,30) } }
                }.padding(20).background(LinleyTheme.pageGradient)
            } else {
                VStack(spacing:8) {
                    HStack {Text("Make it yours").font(.headline);Spacer();CoinBalanceView()}.padding(.horizontal,16)
                    editingStage(height:max(150,min(geo.size.height*0.37,290)))
                    categoryBar.padding(.horizontal,12)
                    ScrollView {
                        VStack(alignment:.leading,spacing:16) {
                            StyleStoreRecoveryView()
                            if moveMode { movementControls }
                            controls
                            if let message=studio.message {Text(message).font(.caption)}
                        }.padding(.horizontal,16).padding(.bottom,24)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }.background(LinleyTheme.pageGradient)
            }
        }
    }
    private var decoratedEditor: some View {
        editorLayout.foregroundStyle(LinleyTheme.plum).preferredColorScheme(.light)
            .navigationTitle("Style Studio").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LinleyTheme.cream,for:.navigationBar).toolbarBackground(.visible,for:.navigationBar)
            .onChange(of:studio.healthy) { old, new in
                if new && !old {look=studio.draft}
            }
            .onChange(of:tab) { _, value in
                faceZoom = [1,2,3].contains(value)
                if value == 1 {selectedLayer="hair"}
                if value == 2 {selectedLayer="face"}
                if value == 3 {selectedLayer="makeup"}
                if value == 4 {selectedLayer="bag"}
            }
            .onAppear {
                look = studio.draft
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--style-editor-review") {
                    look=DressUpLook(hair:"buns",skin:2,bag:"bunny")
                    look.blush=2;look.lipColor=2;look.eyeShadow=3;tab=3
                }
                if ProcessInfo.processInfo.arguments.contains("--style-movement-review") {
                    look=DressUpLook(hair:"braids",skin:3,bag:"kitty",glasses:1)
                    look.placements["bag"]=StylePlacement(x:0.05,y:-0.025,scale:1.2,rotation:-12)
                    tab=4;selectedLayer="bag";moveMode=true
                }
                #endif
                audio.setVisible(scenePhase == .active)
            }
            .onDisappear { audio.setVisible(false); flushDraft() }
            .onChange(of:scenePhase) { _, phase in
                audio.setVisible(phase == .active)
                if phase != .active {flushDraft()}
            }
            .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.interruptionNotification)) { audio.interrupt($0) }
            .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.routeChangeNotification)) { audio.routeChanged($0) }
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button { soundSettings=true } label:{Image(systemName:"speaker.wave.2.fill")}.accessibilityLabel("Studio sound settings") } }
            .sheet(isPresented:$soundSettings) { QuestAudioSettings(audio:audio) }
            .onChange(of:look) { _, next in
                draftSaveTask?.cancel()
                guard next != studio.draft else {return}
                // Slider changes update the preview immediately; coalesce protected file writes.
                draftSaveTask=Task { @MainActor in
                    do {try await Task.sleep(for:.milliseconds(300))} catch {return}
                    guard !Task.isCancelled else {return}
                    persistDraft(next)
                }
            }
    }
    private func persistDraft(_ value: DressUpLook) {
        guard studio.healthy, value != studio.draft else {return}
        do {try studio.update(value)}
        catch {studio.message="That change couldn't save. Your previous look is kept."}
    }
    private func flushDraft() {
        draftSaveTask?.cancel(); draftSaveTask=nil
        persistDraft(look)
    }
    var body: some View {
        decoratedEditor
            .overlay {if studio.isLoading {ProgressView("Opening your studio…").padding(24).background(.regularMaterial,in:RoundedRectangle(cornerRadius:20))}}
            .confirmationDialog("Unlock this style?",isPresented:Binding(get:{pendingPurchase != nil},set:{if !$0 { pendingPurchase=nil }}),titleVisibility:.visible) {
                if let id=pendingPurchase, let item=WardrobeItem.item(id) {
                    Button("Use \(item.cost) coins for \(item.title)") {
                        if game.unlockStyle(id) { wear(item); audio.play("quest-collect.wav"); notice="\(item.title) is yours to reuse." }
                        else { notice="That style couldn't unlock. Your balance has not changed." }
                        pendingPurchase=nil
                    }
                }
                Button("Cancel",role:.cancel) { pendingPurchase=nil }
            } message:{Text("Earned Linley Coins only. No money, subscription or expiration.")}
            .confirmationDialog("Delete this saved look?",isPresented:Binding(get:{deleteID != nil},set:{if !$0 {deleteID=nil}}),titleVisibility:.visible) {
                Button("Delete look",role:.destructive) { if let id=deleteID { do {try studio.delete(id)} catch {notice="The look couldn't delete."} }; deleteID=nil }
                Button("Keep look",role:.cancel) {deleteID=nil}
            }
            .confirmationDialog("Remove private face photos?",isPresented:$clearPhotos,titleVisibility:.visible) {
                Button("Remove photos from all editable looks",role:.destructive) {
                    do {try studio.removeEveryFace(); look.face=nil; notice="Face photos removed from your editable studio looks."}
                    catch {notice="The photos couldn't remove. Your files were kept."}
                }
                Button("Cancel",role:.cancel) {}
            } message:{Text("Finished pictures already saved to My Stuff or Photos are separate copies. You can delete those there.")}
            .sheet(isPresented:$library,onDismiss:presentCrop) {
                LibraryPicker(picturesOnly:true) { result in receivePhoto(result); library=false }
            }
            .fullScreenCover(isPresented:$camera,onDismiss:presentCrop) {
                CameraCapture(video:false,prefersFront:true) { result in receivePhoto(result); camera=false }.ignoresSafeArea()
            }
            .sheet(item:$cropPhoto,onDismiss:{
                if let url=activeCropURL {DressUpStore.cleanupCrop(url)}
                activeCropURL=nil
            }) { draft in
                ProfileCropView(draft:draft,title:"Frame your avatar face") { data in
                    if let data {
                        do { look.face=try DressUpStore.normalizedFace(data) }
                        catch { notice="That photo couldn't open. Try another picture." }
                    }
                    try? FileManager.default.removeItem(at:draft.url); cropPhoto=nil
                }
            }
            .alert("Style Studio",isPresented:Binding(get:{notice != nil},set:{if !$0 {notice=nil}})) {
                Button("OK") {notice=nil}
            } message:{Text(notice ?? "")}
    }
    private var header: some View {
        VStack(alignment:.leading,spacing:10) {
            ViewThatFits(in:.horizontal) {
                HStack {
                    Text("Your style. Your stage.").font(.system(.largeTitle,design:.rounded,weight:.heavy)).foregroundStyle(LinleyTheme.plum).fixedSize()
                    Spacer();CoinBalanceView().fixedSize()
                }
                VStack(alignment:.leading,spacing:10) {
                    Text("Your style. Your stage.").font(.system(.largeTitle,design:.rounded,weight:.heavy)).foregroundStyle(LinleyTheme.plum)
                    CoinBalanceView()
                }
            }
            Text("Make original pop-concert, fan-fashion and storybook looks. Style your illustrated avatar or add your own private photo.")
            Label("Private on this device · No posting or uploads",systemImage:"lock.shield.fill").font(.caption.bold()).foregroundStyle(LinleyTheme.plum)
        }
    }
    private var saveControls: some View {
        VStack(spacing:12) {
            if !lockedItems.isEmpty {
                VStack(alignment:.leading,spacing:8) {
                    Label("Fitting-room preview",systemImage:"eye.fill").font(.headline)
                    Text("Try any style free. Unlock it with earned coins to keep the look or finish a mission.").font(.caption)
                    ForEach(lockedItems) { item in
                        Button("Unlock \(item.title) · \(item.cost) coins") {
                            if game.progress.coins >= item.cost {pendingPurchase=item.id}
                            else {notice="Earn \(item.cost-game.progress.coins) more coins by playing. You can keep trying this style on."}
                        }.buttonStyle(.bordered).accessibilityIdentifier("unlockStyle-\(item.id)")
                    }
                }.padding().background(LinleyTheme.gold.opacity(0.15),in:RoundedRectangle(cornerRadius:18))
            }
            TextField("Name your avatar",text:$title).textFieldStyle(.roundedBorder).onChange(of:title) {_,new in if new.count>40 {title=String(new.prefix(40))} }
                .accessibilityIdentifier("styleTitle")
            HStack {
                Button("Save & use avatar") {
                    do {_ = try studio.save(look,title:title,makeActive:true); notice="Avatar saved! Your character is ready in every game. You can change avatars in Games or keep styling here."}
                    catch {notice=studio.looks.count >= DressUpStore.maximumLooks ? "Your Lookbook holds 24 looks. Delete one to make room." : "Your look couldn't save. Your previous looks were kept."}
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("saveStyleLook")
                Button("Save picture") {savePicture(toPhotos:false)}.buttonStyle(.bordered).accessibilityIdentifier("saveStylePicture")
            }.disabled(!studio.healthy || !game.ownsLook(look))
            Button("Save picture to Photos") {savePicture(toPhotos:true)}.font(.caption).disabled(!game.ownsLook(look)).accessibilityIdentifier("styleSavePhotos")
            Text("Save & use avatar keeps a private editable character for your games. Save picture adds an image to My Stuff. Photos is optional and may sync through iCloud Photos or other services according to your device settings.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var categoryBar: some View {
        LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:4),count:4),spacing:5) {
            ForEach(tabs.indices,id:\.self) { index in
                Button {tab=index;audio.play("quest-step.wav")} label:{
                    VStack(spacing:3) {Image(systemName:tabIcons[index]);Text(tabs[index]).font(.caption.bold())}
                        .frame(maxWidth:.infinity,minHeight:42)
                        .background(tab==index ? LinleyTheme.plum : .white,in:RoundedRectangle(cornerRadius:12))
                        .foregroundStyle(tab==index ? .white : LinleyTheme.plum)
                }.buttonStyle(.plain).accessibilityIdentifier("styleTab-\(index)").accessibilityAddTraits(tab==index ? .isSelected : [])
            }
        }
    }
    private var controls: some View {
        VStack(alignment:.leading,spacing:16) {
            if tab == 0 { wardrobe(.outfit) }
            if tab == 1 { hairControls }
            if tab == 2 { avatarControls }
            if tab == 3 { makeupControls }
            if tab == 4 { extrasControls }
            if tab == 5 { details }
            if tab == 6 { briefCard }
            if tab == 7 { saveControls;lookbook }
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    private func editingStage(height:CGFloat) -> some View {
        let width=height*2/3
        let zoom=faceZoom ? 2.8 : 1.0
        var visibleLook=look
        if moveMode {visibleLook.move(selectedLayer,dx:dragTranslation.width/width/zoom,dy:dragTranslation.height/height/zoom)}
        return HStack(spacing:12) {
            DressUpCanvas(look:visibleLook,title:title)
                .frame(width:width,height:height)
                .scaleEffect(zoom,anchor:UnitPoint(x:0.5,y:0.14))
                .frame(width:width,height:height).clipped()
                .background(.white).clipShape(RoundedRectangle(cornerRadius:20))
                .overlay(RoundedRectangle(cornerRadius:20).stroke(moveMode ? LinleyTheme.coralDeep : .white,lineWidth:3))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:4).updating($dragTranslation) {value,state,_ in state=value.translation}
                    .onEnded {value in look.move(selectedLayer,dx:value.translation.width/width/zoom,dy:value.translation.height/height/zoom)},including:moveMode ? .all : .none)
                .accessibilityIdentifier("stylePreview")
            VStack(alignment:.leading,spacing:12) {
                Button {faceZoom.toggle()} label:{Label(faceZoom ? "Whole look" : "Face detail",systemImage:faceZoom ? "arrow.down.right.and.arrow.up.left" : "plus.magnifyingglass")}.buttonStyle(.bordered).accessibilityIdentifier("styleZoom")
                Button {moveMode.toggle()} label:{Label(moveMode ? "Done moving" : "Move items",systemImage:"hand.draw")}.buttonStyle(.borderedProminent).accessibilityIdentifier("styleMoveMode")
                if moveMode {
                    Picker("Move",selection:$selectedLayer) {ForEach(DressUpLook.movableLayers,id:\.self) {Text(layerNames[$0] ?? $0).tag($0)}}.pickerStyle(.menu)
                    Text("Drag the preview to move this layer. Size and tilt controls are below.").font(.caption)
                    Button("Reset this item") {look.placements.removeValue(forKey:selectedLayer)}.font(.caption.bold())
                } else {
                    Text("Tap a category below to start styling.").font(.caption)
                }
                if !lockedItems.isEmpty {
                    Button {tab=7} label:{Label("Trying on \(lockedItems.count) locked style\(lockedItems.count==1 ? "" : "s")",systemImage:"eye")}.font(.caption.bold())
                }
            }.frame(maxWidth:180,alignment:.leading)
        }.frame(maxWidth:.infinity).padding(.horizontal,12)
    }
    private var movementControls: some View {
        VStack(alignment:.leading,spacing:8) {
            Text("Adjust \(layerNames[selectedLayer] ?? selectedLayer)").font(.headline)
            placementSlider("Left / right",keyPath:\.x,range:-0.3...0.3)
            placementSlider("Up / down",keyPath:\.y,range:-0.3...0.3)
            placementSlider("Size",keyPath:\.scale,range:0.6...1.6)
            placementSlider("Tilt",keyPath:\.rotation,range:-45...45)
            Button("Reset all positions") {look.placements=[:]}.font(.caption.bold())
        }.padding(12).background(.white,in:RoundedRectangle(cornerRadius:16))
    }
    private func placementSlider(_ title:String,keyPath:WritableKeyPath<StylePlacement,Double>,range:ClosedRange<Double>) -> some View {
        HStack {Text(title).font(.caption).frame(width:78,alignment:.leading)
            Slider(value:Binding(get:{look.placement(selectedLayer)[keyPath:keyPath]},set:{value in var p=look.placement(selectedLayer);p[keyPath:keyPath]=value;look.placements[selectedLayer]=p}),in:range)
                .accessibilityLabel(title).accessibilityIdentifier("styleAdjust-\(title)")
        }
    }
    private func wardrobe(_ kind:WardrobeItem.Kind) -> some View {
        VStack(alignment:.leading,spacing:12) {
            Text(kind == .outfit ? "The wardrobe" : kind == .hair ? "Hair studio" : "Cute companion shop").font(.title2.bold())
            Text("Tap to try it on. Unlock favorites with game coins. Wear forever.").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns:[GridItem(.adaptive(minimum:145))],spacing:12) {
                ForEach((WardrobeItem.all + WardrobeItem.bags).filter {$0.kind == kind}) { item in
                    Button {
                        wear(item)
                    } label:{
                        VStack(alignment:.leading,spacing:8) {
                            if kind == .outfit {
                                if let image=StyleArt.images[item.art] {
                                    Image(uiImage:image).resizable().scaledToFit().hueRotation(.degrees(item.hue))
                                        .frame(height:155).frame(maxWidth:.infinity).background(LinleyTheme.cream,in:RoundedRectangle(cornerRadius:15))
                                }
                            } else if kind == .bag {
                                StyleCompanion(id:item.id).frame(height:110).frame(maxWidth:.infinity)
                            } else {
                                if let hair=StyleArt.images[item.art] {
                                    Image(uiImage:hair).resizable().scaledToFit().frame(maxWidth:.infinity).frame(height:95)
                                }
                            }
                            Text(item.title).font(.headline)
                            Text(item.note).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
                            Label(game.ownsStyle(item.id) ? (selected(item) ? "Wearing" : "Owned · wear it") : (selected(item) ? "Preview · \(item.cost) coins" : "Try on · \(item.cost) coins"),systemImage:game.ownsStyle(item.id) ? "checkmark.circle.fill" : "sparkles").font(.caption.bold())
                            if !game.ownsStyle(item.id), game.progress.coins < item.cost {Text("\(item.cost-game.progress.coins) more coins needed").font(.caption2)}
                        }.padding(12).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(LinleyTheme.plum)
                            .background(.white,in:RoundedRectangle(cornerRadius:20))
                            .overlay(RoundedRectangle(cornerRadius:20).stroke(selected(item) ? LinleyTheme.coralDeep : .clear,lineWidth:2))
                    }.buttonStyle(.plain).disabled(game.loadError)
                        .accessibilityIdentifier("styleItem-\(item.id)")
                }
            }
        }
    }
    private var hairControls: some View {
        VStack(alignment:.leading,spacing:14) {
            wardrobe(.hair)
            Text("Hair color").font(.headline)
            HStack {ForEach(0..<4,id:\.self) {i in
                Button {look.hairColor=i} label:{Circle().fill(DressUpCanvas.hair[i]).frame(width:38,height:38).overlay(Circle().stroke(look.hairColor==i ? LinleyTheme.coralDeep : .white,lineWidth:3))}.accessibilityLabel(["Chocolate","Golden brown","Midnight","Berry"][i])
            }}
        }
    }
    private var avatarControls: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Face studio").font(.title2.bold())
            Picker("Face shape",selection:$look.faceStyle) { Text("Soft oval").tag(0);Text("Round").tag(1);Text("Drawn").tag(2) }.pickerStyle(.segmented).accessibilityIdentifier("styleFaceShape")
            Text("Avatar skin tone").font(.headline)
            HStack {ForEach(0..<4,id:\.self) {i in
                Button {look.skin=i;look.face=nil;audio.play("quest-step.wav")} label:{Circle().fill(DressUpCanvas.skin[i]).frame(width:38,height:38).overlay(Circle().stroke(look.skin==i ? LinleyTheme.coralDeep : .white,lineWidth:3))}.accessibilityLabel("Skin tone \(i+1)").accessibilityIdentifier("styleSkin-\(i)")
            }}
            Text("Tone buttons use an illustrated face. Your photo keeps its own colors.").font(.caption).foregroundStyle(.secondary)
            Text("Your private photo avatar").font(.headline)
            Text("Choose a clear front-facing photo, then zoom in around your face. It becomes the face of your illustrated avatar. Hair is an added illustrated layer.").font(.caption)
            Button("Choose a photo") {library=true}.buttonStyle(.bordered).accessibilityIdentifier("styleChoosePhoto")
            Button("Take a selfie") {Task {
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {notice="Camera capture needs a physical device.";return}
                guard await CameraAccess.request(video:false) else {notice="Camera access is off. You can choose a photo instead.";return}
                camera=true
            }}.buttonStyle(.bordered)
            if media.profileData != nil {
                Button("Use my existing profile photo") {
                    if let data=media.profileData {
                        do {look.face=try DressUpStore.normalizedFace(data)} catch {notice="Your profile photo couldn't open."}
                    }
                }
            }
            if look.face != nil {
                Button("Use illustrated face") {look.face=nil}
                Button("Remove photos from all editable looks",role:.destructive) {clearPhotos=true}
            }
        }
    }
    private var makeupControls: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Makeup studio").font(.title2.bold())
            Text("Zoom in, choose colors, then move the makeup layer to fit your face. All makeup is free.").font(.caption)
            palettePicker("Blush",selection:$look.blush)
            palettePicker("Lip color",selection:$look.lipColor)
            palettePicker("Eye shadow",selection:$look.eyeShadow)
            Toggle("Stage shimmer",isOn:Binding(get:{look.makeup==3},set:{look.makeup=$0 ? 3 : 0}))
            Button("Remove all makeup") {look.makeup=0;look.blush=0;look.lipColor=0;look.eyeShadow=0}
            Text("Illustrated makeup overlays; use Move items to adjust their position.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func palettePicker(_ name:String,selection:Binding<Int>) -> some View {
        VStack(alignment:.leading,spacing:6) {
            Text(name).font(.headline)
            Picker(name,selection:selection) {Text("None").tag(0);Text("Peach").tag(1);Text("Rose").tag(2);Text("Berry").tag(3)}.pickerStyle(.segmented).accessibilityIdentifier("stylePalette-\(name)")
        }
    }
    private var extrasControls: some View {
        VStack(alignment:.leading,spacing:14) {
            wardrobe(.bag)
            Text("Glasses").font(.headline)
            Picker("Glasses",selection:$look.glasses) { Text("None").tag(0);Text("Round").tag(1);Text("Star shades").tag(2) }.pickerStyle(.segmented)
            Toggle("Animal-ear headband",isOn:$look.animalEars)
            Text("Clips & headphones").font(.headline)
            ForEach(0..<4,id:\.self) {i in Button {look.accessory=i} label:{Label(["None","Star clip","Ribbon","Headphones"][i],systemImage:look.accessory==i ? "checkmark.circle.fill" : "circle")}.buttonStyle(.bordered)}
        }
    }
    private var details: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Set the scene").font(.title2.bold())
            ForEach(0..<4,id:\.self) {i in Button {look.backdrop=i} label:{Label(DressUpCanvas.scenes[i],systemImage:look.backdrop==i ? "checkmark.circle.fill" : "circle").frame(maxWidth:.infinity,alignment:.leading)}.buttonStyle(.bordered).accessibilityIdentifier("styleScene-\(i)")}
            Text("Finishing details").font(.headline)
            ForEach(0..<4,id:\.self) {i in Button {look.accessory=i} label:{Label(["Keep it simple","Star clip","Ribbon","Headphones"][i],systemImage:look.accessory==i ? "checkmark.circle.fill" : "circle").frame(maxWidth:.infinity,alignment:.leading)}.buttonStyle(.bordered).accessibilityIdentifier("styleAccessory-\(i)")}
        }
    }
    private var lookbook: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Your avatars & Lookbook").font(.title2.bold())
            if studio.looks.isEmpty {Text("Save an avatar to bring your style into the other games. Nothing is posted or uploaded.")}
            LazyVGrid(columns:[GridItem(.adaptive(minimum:140))],spacing:12) {
                ForEach(studio.looks) {saved in
                    VStack {
                        Button {
                            var restored=saved.look
                            if !game.ownsStyle(restored.outfit) {restored.outfit="lavender"}
                            if !game.ownsStyle(restored.hair) {restored.hair="bob"}
                            if !game.ownsStyle(restored.bag) {restored.bag="simple"}
                            look=restored;title=saved.title
                        } label:{DressUpCanvas(look:saved.look,title:saved.title).clipShape(RoundedRectangle(cornerRadius:15))}
                            .accessibilityLabel("Open \(saved.title)")
                        Button {
                            do {try studio.selectAvatar(saved.id);notice="\(saved.title) is ready in your games."}
                            catch {notice="That avatar couldn't be selected. Your previous character is kept."}
                        } label: { Label(studio.selectedAvatarID == saved.id ? "Playing as this avatar" : "Use in games",systemImage:studio.selectedAvatarID == saved.id ? "checkmark.circle.fill" : "person.crop.circle") }
                            .font(.caption.bold()).buttonStyle(.bordered).accessibilityIdentifier("useAvatar-\(saved.id)")
                        Button("Delete look",role:.destructive) {deleteID=saved.id}.font(.caption)
                    }
                }
            }
        }
    }
    private var briefCard: some View {
        let challenge=StyleBrief.all[brief]
        return VStack(alignment:.leading,spacing:12) {
            Text("Styling missions").font(.title2.bold())
            Picker("Choose a mission",selection:$brief) {ForEach(StyleBrief.all) {Text($0.title).tag($0.id)}}
            Text(challenge.instruction)
            Text("Any outfit and hair work. Express yourself; there are no beauty scores. First completion earns 100 Linley Coins.").font(.caption).foregroundStyle(.secondary)
            Button(game.progress.styleBriefs.contains(brief) ? "Mission complete" : "Finish mission · +100 coins") {
                let completed=game.completeStyleBrief(brief,look:look)
                if completed {audio.play("quest-win.wav")}
                notice=completed ? "Mission complete! 100 Linley Coins added to your shared wallet." : "Choose the scene and accessory in the brief first. No coins changed."
            }.buttonStyle(.borderedProminent).disabled(game.loadError || game.progress.styleBriefs.contains(brief) || !challenge.met(by:look) || !game.ownsLook(look))
                .accessibilityIdentifier("finishStyleBrief")
        }.padding(18).background(LinleyTheme.sky.opacity(0.14),in:RoundedRectangle(cornerRadius:22))
    }
    private var lockedItems: [WardrobeItem] { look.styleIDs.compactMap { WardrobeItem.item($0) }.filter { !game.ownsStyle($0.id) } }
    private func selected(_ item:WardrobeItem)->Bool { item.kind == .outfit ? look.outfit==item.id : item.kind == .hair ? look.hair==item.id : look.bag==item.id }
    private func wear(_ item:WardrobeItem) {
        audio.play("quest-step.wav")
        withAnimation(.easeInOut(duration:0.2)) {
            if item.kind == .outfit {look.outfit=item.id} else if item.kind == .hair {look.hair=item.id} else {look.bag=item.id}
        }
    }
    private func receivePhoto(_ result:Result<DraftMedia?,Error>) {
        switch result {case .success(let draft):
            if let draft {
                defer {try? FileManager.default.removeItem(at:draft.url)}
                do {pendingPhoto=DraftMedia(url:try DressUpStore.prepareCrop(draft.url),kind:.picture)}
                catch {notice="That photo couldn't open. Your previous avatar is kept."}
            }
        case .failure:notice="That photo couldn't open. Your previous avatar is kept."}
    }
    private func presentCrop() {activeCropURL=pendingPhoto?.url;cropPhoto=pendingPhoto;pendingPhoto=nil}
    @MainActor private func renderedPicture()->UIImage? {
        let renderer=ImageRenderer(content:DressUpCanvas(look:look,title:title).frame(width:720,height:1080));renderer.scale=1
        return renderer.uiImage
    }
    @MainActor private func savePicture(toPhotos:Bool) {
        guard game.ownsLook(look) else {notice="Unlock the preview styles before saving a picture.";return}
        guard let image=renderedPicture() else {notice="The picture couldn't render. Your editable look is safe.";return}
        if toPhotos {
            Task {
                let status=await PHPhotoLibrary.requestAuthorization(for:.addOnly)
                guard status == .authorized || status == .limited else {notice="Photos access is off. You can still save privately to My Stuff.";return}
                do {try await PHPhotoLibrary.shared().performChanges {PHAssetChangeRequest.creationRequestForAsset(from:image)};notice="Picture saved to your Photos. Your Photos settings control any personal cloud syncing."}
                catch {notice="The picture couldn't save to Photos. Your editable look is safe."}
            }
        } else {
            let temporary=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".jpg")
            defer {try? FileManager.default.removeItem(at:temporary)}
            do {
                guard let data=image.jpegData(compressionQuality:0.92) else {throw CocoaError(.fileWriteUnknown)}
                try data.write(to:temporary,options:[.atomic,.completeFileProtection]);_ = try media.save(source:temporary,kind:.picture)
                notice="Picture saved privately to My Stuff."
            } catch {notice="The picture couldn't save. Your editable look is safe."}
        }
    }
}
