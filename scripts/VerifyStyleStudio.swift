import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@main @MainActor struct VerifyStyleStudio {
    static func main() async throws {
        func check(_ value:@autoclosure ()->Bool,_ message:String) {precondition(value(),message)}
        let suite="LinleyStyleSmoke.\(UUID())"
        let defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        let game=QuestStore(defaults:defaults)
        check(game.ownsStyle("lavender") && game.ownsStyle("bob"),"Free starter")
        check(!game.unlockStyle("moonlight") && game.progress.coins == 0,"No overspend")
        var look=DressUpLook();look.accessory=1
        check(game.completeStyleBrief(0,look:look),"Free mission reward")
        check(game.progress.coins==100 && game.progress.coinsEarned==100,"Shared mission coins")
        check(!game.completeStyleBrief(0,look:look),"No duplicate mission reward")
        check(game.unlockStyle("mint"),"Wardrobe purchase")
        check(game.progress.coins==0 && game.ownsStyle("mint"),"Debit and ownership")
        check(!game.unlockStyle("mint") && !game.unlockStyle("missing"),"No duplicate/unknown purchase")
        let restored=QuestStore(defaults:defaults)
        check(restored.ownsStyle("mint") && restored.progress.coins==0 && QuestStore.valid(restored.progress),"Wallet reload")
        for brief in StyleBrief.all.dropFirst() {
            look.backdrop=brief.backdrop;look.accessory=brief.accessory
            check(game.completeStyleBrief(brief.id,look:look),"Mission completion")
        }
        check(game.progress.coins==500 && game.progress.coinsEarned==600,"Six fixed mission rewards")
        check(game.unlockStyle("buns") && game.progress.coins==300,"Paid hairstyle")
        check(game.unlockPack("garden") && game.progress.coins==200,"Same wallet art shop")
        check(QuestStore.valid(game.progress),"Combined economy ledger")
        var illegal=look;illegal.outfit="moonlight";illegal.backdrop=0;illegal.accessory=1
        let freshDefaults=UserDefaults(suiteName:"LinleyStyleEmptyTemporary")!
        defer {freshDefaults.removePersistentDomain(forName:"LinleyStyleEmptyTemporary") }
        check(!QuestStore(defaults:freshDefaults).completeStyleBrief(0,look:illegal),"Unowned outfit cannot earn")
        var preview=look;preview.bag="dumpling"
        let balanceBefore=game.progress.coins
        check(preview.valid && !game.ownsLook(preview) && game.progress.coins==balanceBefore,"Fitting room does not buy")
        check(game.unlockStyle("dumpling") && game.ownsLook(preview),"Bag ownership joins wardrobe")
        check(!game.unlockStyle("dumpling") && game.progress.coins==balanceBefore-100,"No repeat bag debit")
        let bagReload=QuestStore(defaults:defaults)
        check(bagReload.ownsLook(preview) && QuestStore.valid(bagReload.progress),"Bag ledger reload")
        let oldLook=Data(#"{"outfit":"lavender","hair":"bob","skin":1,"hairColor":0,"backdrop":0,"accessory":0}"#.utf8)
        let migratedLook=try JSONDecoder().decode(DressUpLook.self,from:oldLook)
        check(migratedLook==DressUpLook(),"Old editable looks migrate without new fields")
        let oldPalette=Data(#"{"outfit":"lavender","hair":"bob","skin":1,"hairColor":0,"backdrop":0,"accessory":0,"makeup":2}"#.utf8)
        let paletteMigration=try JSONDecoder().decode(DressUpLook.self,from:oldPalette)
        check(paletteMigration.blush==2 && paletteMigration.makeup==0 && paletteMigration.valid,"Old makeup remains editable as separate blush")
        preview.glasses=2;preview.makeup=3;preview.animalEars=true
        let detailedReload=try JSONDecoder().decode(DressUpLook.self,from:JSONEncoder().encode(preview))
        check(detailedReload==preview,"Details round trip")
        var unpaidBag=DressUpLook();unpaidBag.bag="kitty";unpaidBag.accessory=1
        let freshGame=QuestStore(defaults:freshDefaults)
        check(!freshGame.completeStyleBrief(0,look:unpaidBag) && freshGame.progress.coins==0,"Preview bag cannot earn a mission reward")
        var invalidDetails=DressUpLook();invalidDetails.makeup=4
        check(!invalidDetails.valid,"Unknown palettes rejected")
        print("PASS: fitting room ownership, companion purchases, old looks and detailed-look persistence")
        print("PASS: free wardrobe, six rewards, permanent purchases, no overspend/duplicate, shared shop and reload")
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("style-smoke-\(UUID())",isDirectory:true)
        defer {try? FileManager.default.removeItem(at:root)}
        let store=DressUpStore(root:root)
        check(store.healthy,"Private folder")
        let context=CGContext(data:nil,width:1024,height:768,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red:0.3,green:0.6,blue:0.9,alpha:1));context.fill(CGRect(x:0,y:0,width:1024,height:768))
        let data=NSMutableData(),destination=CGImageDestinationCreateWithData(data,UTType.jpeg.identifier as CFString,1,nil)!
        CGImageDestinationAddImage(destination,context.makeImage()!,[kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:40.0,kCGImagePropertyGPSLongitude:70.0]] as CFDictionary)
        check(CGImageDestinationFinalize(destination),"Synthetic test photo")
        let face=try DressUpStore.normalizedFace(data as Data)
        let source=CGImageSourceCreateWithData(face as CFData,nil)!, properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil)! as NSDictionary
        check(properties[kCGImagePropertyGPSDictionary]==nil,"Strip source GPS")
        check((properties[kCGImagePropertyPixelWidth] as! Int)<=512,"Bound face pixels")
        var privateLook=DressUpLook();privateLook.face=face
        privateLook.faceStyle=1;privateLook.lipColor=2;privateLook.eyeShadow=3;privateLook.blush=1
        privateLook.move("bag",dx:0.2,dy:-0.1)
        privateLook.placements["glasses"]=StylePlacement(x:0.02,y:-0.03,scale:1.3,rotation:15)
        var moved=privateLook;moved.move("hair",dx:100,dy:-100)
        check(moved.valid && moved.placement("hair").x==0.3 && moved.placement("hair").y == -0.3,"Drag remains inside editor bounds")
        var unknownLayer=privateLook;unknownLayer.placements["unknown"]=StylePlacement()
        check(!unknownLayer.valid,"Unknown layer rejected")
        var invalidTransform=privateLook;invalidTransform.placements["hair"]=StylePlacement(scale:100)
        check(!invalidTransform.valid,"Oversized layer rejected")
        var nonFinite=privateLook;nonFinite.placements["hair"]=StylePlacement(x:.nan)
        check(!nonFinite.valid,"Nonfinite placement rejected")
        try store.update(privateLook)
        let id=try store.save(privateLook,title:"  My fan look  ",makeActive:true)
        check(store.selectedAvatarID == id && store.selectedAvatar?.look == privateLook,"Saved avatar selected atomically")
        let loaded=DressUpStore(root:root)
        check(loaded.draft==privateLook && loaded.looks.first?.title=="My fan look","Private editable persistence")
        check(loaded.selectedAvatarID == id && loaded.selectedAvatar?.look == privateLook,"Selected avatar survives reload")
        do {try loaded.selectAvatar(UUID());fatalError("Unknown avatar accepted")} catch {}
        check(loaded.selectedAvatarID == id,"Rejected selection keeps active avatar")
        try loaded.selectAvatar(nil)
        check(loaded.selectedAvatar == nil && DressUpStore(root:root).selectedAvatarID == nil,"Original hero selection persists")
        try loaded.selectAvatar(id)
        var paid=privateLook;paid.outfit="moonlight";paid.hair="braids";paid.bag="kitty"
        let paidID=try loaded.save(paid,title:"Fancy",makeActive:true)
        let fallback=loaded.gameLook(ownsStyle:{_ in false})!
        check(fallback.outfit=="lavender" && fallback.hair=="bob" && fallback.bag=="simple" && fallback.face==face,"Reset wallet falls back without losing avatar identity")
        check(loaded.selectedAvatar?.look==paid,"Fallback doesn't alter saved artwork")
        try loaded.delete(paidID)
        check(loaded.selectedAvatar == nil,"Deleting selected avatar restores original hero")
        try loaded.selectAvatar(id)
        let backupExcluded = try root.resourceValues(forKeys:[.isExcludedFromBackupKey]).isExcludedFromBackup
        check(backupExcluded==true,"Excluded from backup")
        try loaded.removeEveryFace()
        check(loaded.draft.face==nil && loaded.looks.allSatisfy {$0.look.face==nil},"Remove face copies")
        check(loaded.selectedAvatar?.look.face == nil && loaded.selectedAvatarID == id,"Face removal reaches selected avatar without changing selection")
        check(DressUpStore(root:root).looks.first?.look.face==nil,"Removal persisted")
        try loaded.delete(id);check(loaded.looks.isEmpty && loaded.selectedAvatarID == nil,"Saved look deletion")
        let legacyDocument=try JSONSerialization.jsonObject(with:JSONEncoder().encode(DressUpStore.Document(draft:DressUpLook(),looks:[]))) as! [String:Any]
        check(legacyDocument["selectedAvatarID"] == nil,"Old documents omit avatar selection")
        try JSONSerialization.data(withJSONObject:legacyDocument).write(to:root.appendingPathComponent("studio.json"))
        check(DressUpStore(root:root).healthy && DressUpStore(root:root).selectedAvatarID == nil,"Legacy private studio opens with original hero")
        print("PASS: avatar selection, reload, unknown ID, deselection, wallet reset fallback, face removal, selected deletion and legacy migration")
        var bad=DressUpLook();bad.outfit="../escape"
        do {try loaded.update(bad);fatalError("Invalid look accepted")} catch {}
        check(loaded.draft.valid,"Rejected write retained previous draft")
        do {_ = try DressUpStore.normalizedFace(Data([1,2,3]));fatalError("Invalid photo accepted")} catch {}
        print("PASS: private look save/reopen/delete, photo normalization/GPS stripping, backup exclusion and face removal")
        for i in 0..<DressUpStore.maximumLooks {_ = try loaded.save(DressUpLook(),title:"Look \(i)")}
        do {_ = try loaded.save(DressUpLook(),title:"Overflow");fatalError("Unbounded look storage")} catch {}
        let file=root.appendingPathComponent("studio.json"), corrupt=Data([0,1,2,3]);try corrupt.write(to:file)
        let damaged=DressUpStore(root:root)
        check(!damaged.healthy && damaged.message != nil,"Corrupt store fails closed")
        let preserved = try Data(contentsOf:file)
        check(preserved==corrupt,"Corrupt file preserved")
        do {try damaged.removeEveryFace();fatalError("Unreadable studio mutated")} catch {}
        let stillUnreadable=try Data(contentsOf:file)
        check(stillUnreadable==corrupt,"Unreadable library retained until explicit reset")
        try damaged.resetUnreadable()
        check(damaged.healthy && damaged.looks.isEmpty && damaged.selectedAvatarID == nil,"Explicit unreadable reset clears private library")
        let recoveredID=try damaged.save(DressUpLook(),title:"Recovered",makeActive:true)
        check(DressUpStore(root:root).selectedAvatarID == recoveredID,"Save works after unreadable reset")
        do {try damaged.resetUnreadable();fatalError("Healthy library reset without unreadable state")} catch {}
        let delayed=DressUpStore(root:root,deferredLoad:true)
        check(delayed.isLoading && !delayed.healthy && delayed.looks.isEmpty,"Deferred load doesn't synchronously read library")
        do {try delayed.update(DressUpLook());fatalError("Loading library mutated")} catch {}
        do {try delayed.resetUnreadable();fatalError("Loading library reset")} catch {}
        await delayed.loadIfNeeded()
        check(!delayed.isLoading && delayed.healthy && delayed.selectedAvatarID == recoveredID,"Deferred library publishes loaded selection")
        let newestID=try delayed.save(DressUpLook(),title:"Latest",makeActive:true)
        await delayed.loadIfNeeded()
        check(delayed.selectedAvatarID == newestID,"Repeated load cannot overwrite latest edits")
        let input=root.appendingPathComponent("crop-input.jpg");try face.write(to:input)
        let crop=try DressUpStore.prepareCrop(input)
        check(crop.deletingLastPathComponent().lastPathComponent=="linley-style-crops" && FileManager.default.fileExists(atPath:crop.path),"Crop lives in owned private temp directory")
        DressUpStore.cleanupCrop(input)
        check(FileManager.default.fileExists(atPath:input.path),"Crop cleanup ignores unrelated files")
        DressUpStore.cleanupCrop(crop)
        check(!FileManager.default.fileExists(atPath:crop.path),"Canceled crop cleanup removes owned file")
        let orphan=try DressUpStore.prepareCrop(input)
        _=DressUpStore(root:root)
        check(!FileManager.default.fileExists(atPath:orphan.path) && FileManager.default.fileExists(atPath:input.path),"Startup purges orphan crop without sweeping other temp files")
        print("PASS: deferred single load, loading mutation guard, explicit unreadable reset, recovery save, and scoped crop cleanup")
        var legacy=QuestProgress();legacy.coins=100;legacy.coinsEarned=100
        var object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(legacy)) as! [String:Any]
        object.removeValue(forKey:"wardrobe");object.removeValue(forKey:"styleBriefs")
        defaults.set(try JSONSerialization.data(withJSONObject:object),forKey:"linley.creativeQuest.v1")
        let migrated=QuestStore(defaults:defaults)
        check(!migrated.loadError && migrated.progress.coins==100 && migrated.progress.wardrobe.isEmpty,"Existing wallet migration")
        print("PASS: bounded storage, corrupt-file preservation, unknown item guard and legacy wallet migration")
    }
}
