import Foundation

struct WardrobeItem: Identifiable {
    enum Kind: String { case outfit, hair, bag }
    let id: String
    let title: String
    let kind: Kind
    let cost: Int
    let art: String
    let hue: Double
    let note: String
    static let all: [WardrobeItem] = [
        .init(id:"lavender",title:"Lavender Encore",kind:.outfit,cost:0,art:"outfit-pop",hue:0,note:"Pearl bomber, star stitching and cargo trousers"),
        .init(id:"mint",title:"Mint Daydream",kind:.outfit,cost:100,art:"outfit-mint",hue:0,note:"Daisy denim and candy-colored high tops"),
        .init(id:"coral",title:"Coral Spotlight",kind:.outfit,cost:200,art:"outfit-pop",hue:85,note:"A warm remix of the concert co-ord"),
        .init(id:"emerald",title:"Emerald Storybook",kind:.outfit,cost:300,art:"outfit-fantasy",hue:0,note:"Embroidered velvet, a little cape and adventure boots"),
        .init(id:"midnight",title:"Midnight Headliner",kind:.outfit,cost:400,art:"outfit-mint",hue:55,note:"A cool-toned denim fan-fashion remix"),
        .init(id:"pinkcloud",title:"Pink Cloud Party",kind:.outfit,cost:500,art:"outfit-dress",hue:0,note:"Starry tulle, a soft cardigan and ribbon high tops"),
        .init(id:"moonlight",title:"Moonlight Icon",kind:.outfit,cost:600,art:"outfit-fantasy",hue:85,note:"A jewel-toned storybook remix"),
        .init(id:"bob",title:"Soft bob",kind:.hair,cost:0,art:"hair-bob",hue:0,note:"A glossy rounded bob"),
        .init(id:"waves",title:"Silky waves",kind:.hair,cost:100,art:"hair-waves",hue:0,note:"Long soft illustrated waves"),
        .init(id:"buns",title:"Double star buns",kind:.hair,cost:200,art:"hair-buns",hue:0,note:"Two playful buns for a stage look"),
        .init(id:"braids",title:"Twin braids",kind:.hair,cost:300,art:"hair-braids",hue:0,note:"A neat pair of braided tails")
    ]
    static let bags: [WardrobeItem] = [
        .init(id:"simple",title:"Hands free",kind:.bag,cost:0,art:"",hue:0,note:"Let your outfit shine"),
        .init(id:"dumpling",title:"Dumpling buddy",kind:.bag,cost:100,art:"",hue:0,note:"A smiling little crossbody companion"),
        .init(id:"bunny",title:"Cloud bunny bag",kind:.bag,cost:200,art:"",hue:0,note:"Soft lilac ears and a tiny heart nose"),
        .init(id:"bear",title:"Honey bear backpack",kind:.bag,cost:300,art:"",hue:0,note:"A teddy-inspired mini backpack"),
        .init(id:"kitty",title:"Star kitty bag",kind:.bag,cost:400,art:"",hue:0,note:"A mint cat companion for your fan look")
    ]
    static func item(_ id: String) -> WardrobeItem? { (all + bags).first { $0.id == id } }
}

struct StylePlacement: Codable, Equatable {
    var x: Double = 0
    var y: Double = 0
    var scale: Double = 1
    var rotation: Double = 0
    var valid: Bool { x.isFinite && y.isFinite && scale.isFinite && rotation.isFinite && abs(x)<=0.3 && abs(y)<=0.3 && (0.6...1.6).contains(scale) && abs(rotation)<=45 }
}

struct DressUpLook: Codable, Equatable {
    static let movableLayers = ["hair","face","bag","glasses","accessory","makeup","ears"]
    var placements: [String:StylePlacement] = [:]
    var faceStyle = 0
    var lipColor = 0
    var eyeShadow = 0
    var blush = 0

    var outfit = "lavender"
    var hair = "bob"
    var skin = 1
    var hairColor = 0
    var backdrop = 0
    var accessory = 0
    var face: Data?
    var bag = "simple"
    var glasses = 0
    var makeup = 0
    var animalEars = false
    init(outfit:String = "lavender",hair:String = "bob",skin:Int = 1,hairColor:Int = 0,backdrop:Int = 0,accessory:Int = 0,face:Data? = nil,bag:String = "simple",glasses:Int = 0,makeup:Int = 0,animalEars:Bool = false) {
        self.outfit=outfit;self.hair=hair;self.skin=skin;self.hairColor=hairColor;self.backdrop=backdrop;self.accessory=accessory;self.face=face
        self.bag=bag;self.glasses=glasses;self.makeup=makeup;self.animalEars=animalEars
    }
    enum CodingKeys: String, CodingKey { case outfit,hair,skin,hairColor,backdrop,accessory,face,bag,glasses,makeup,animalEars,placements,faceStyle,lipColor,eyeShadow,blush }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy:CodingKeys.self)
        outfit = try c.decode(String.self,forKey:.outfit)
        hair = try c.decode(String.self,forKey:.hair)
        skin = try c.decode(Int.self,forKey:.skin)
        hairColor = try c.decode(Int.self,forKey:.hairColor)
        backdrop = try c.decode(Int.self,forKey:.backdrop)
        accessory = try c.decode(Int.self,forKey:.accessory)
        face = try c.decodeIfPresent(Data.self,forKey:.face)
        bag = try c.decodeIfPresent(String.self,forKey:.bag) ?? "simple"
        glasses = try c.decodeIfPresent(Int.self,forKey:.glasses) ?? 0
        makeup = try c.decodeIfPresent(Int.self,forKey:.makeup) ?? 0
        animalEars = try c.decodeIfPresent(Bool.self,forKey:.animalEars) ?? false
        placements = try c.decodeIfPresent([String:StylePlacement].self,forKey:.placements) ?? [:]
        faceStyle = try c.decodeIfPresent(Int.self,forKey:.faceStyle) ?? 0
        lipColor = try c.decodeIfPresent(Int.self,forKey:.lipColor) ?? 0
        eyeShadow = try c.decodeIfPresent(Int.self,forKey:.eyeShadow) ?? 0
        blush = try c.decodeIfPresent(Int.self,forKey:.blush) ?? ((makeup == 1 || makeup == 2) ? makeup : 0)
        if makeup == 1 || makeup == 2 {makeup=0}
    }
    func placement(_ id:String) -> StylePlacement { placements[id] ?? StylePlacement() }
    mutating func move(_ id:String,dx:Double,dy:Double) {
        guard Self.movableLayers.contains(id), dx.isFinite,dy.isFinite else {return}
        var p=placement(id);p.x=max(-0.3,min(0.3,p.x+dx));p.y=max(-0.3,min(0.3,p.y+dy));placements[id]=p
    }
    var styleIDs: [String] { [outfit,hair,bag] }
    var valid: Bool {
        placements.allSatisfy { Self.movableLayers.contains($0.key) && $0.value.valid } &&
        (0..<3).contains(faceStyle) && (0..<4).contains(lipColor) && (0..<4).contains(eyeShadow) && (0..<4).contains(blush) &&
        WardrobeItem.item(outfit)?.kind == .outfit && WardrobeItem.item(hair)?.kind == .hair &&
        (0..<4).contains(skin) && (0..<4).contains(hairColor) && (0..<4).contains(backdrop) &&
        WardrobeItem.item(bag)?.kind == .bag && (0..<3).contains(glasses) && (0..<4).contains(makeup) && (0..<4).contains(accessory) && (face?.count ?? 0) <= 1_000_000
    }
}

struct StyleBrief: Identifiable {
    let id: Int
    let title: String
    let instruction: String
    let backdrop: Int
    let accessory: Int
    static let all = [
        StyleBrief(id:0,title:"Opening Night",instruction:"Build a concert look: Spotlight scene + star clip.",backdrop:0,accessory:1),
        StyleBrief(id:1,title:"Dream Board",instruction:"Make a soft inspiration-board look: Daydream scene + ribbon.",backdrop:1,accessory:2),
        StyleBrief(id:2,title:"Character Chapter",instruction:"Tell your own story: Storybook scene + star clip.",backdrop:2,accessory:1),
        StyleBrief(id:3,title:"Fan Playlist",instruction:"Style your music mood: Spotlight scene + headphones.",backdrop:0,accessory:3),
        StyleBrief(id:4,title:"Studio Portrait",instruction:"Make a profile look: Studio scene + ribbon.",backdrop:3,accessory:2),
        StyleBrief(id:5,title:"Dream Concert",instruction:"Mix your influences: Daydream scene + headphones.",backdrop:1,accessory:3)
    ]
    func met(by look: DressUpLook) -> Bool { look.valid && look.backdrop == backdrop && look.accessory == accessory }
}
