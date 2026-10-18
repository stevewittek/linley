import SwiftUI

@MainActor enum StyleArt {
    static let images: [String:UIImage] = {
        var images: [String:UIImage] = [:]
        for name in ["outfit-pop", "outfit-mint", "outfit-fantasy", "outfit-dress", "hair-waves", "hair-bob", "hair-buns", "hair-braids", "faces"] {
            if let url = Bundle.main.url(forResource:name,withExtension:"png",subdirectory:"DressUp"),
               let image = UIImage(contentsOfFile:url.path) { images[name] = image }
        }
        return images
    }()
    // Four original fictional heads in a 2×2 sprite atlas; trim transparent padding once.
    static let faces: [UIImage] = {
        guard let atlas=images["faces"]?.cgImage else {return []}
        var result:[UIImage]=[]
        for i in 0..<4 {
            let rect=CGRect(x:(i%2)*atlas.width/2,y:(i/2)*atlas.height/2,width:atlas.width/2,height:atlas.height/2)
            guard let cell=atlas.cropping(to:rect) else {return []}
            let w=cell.width,h=cell.height
            var pixels=[UInt8](repeating:0,count:w*h*4)
            pixels.withUnsafeMutableBytes { ptr in
                let context=CGContext(data:ptr.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)
                context?.draw(cell,in:CGRect(x:0,y:0,width:w,height:h))
            }
            var minX=w,minY=h,maxX=0,maxY=0
            for y in 0..<h {for x in 0..<w where pixels[(y*w+x)*4+3] > 24 {
                minX=min(minX,x);minY=min(minY,y);maxX=max(maxX,x);maxY=max(maxY,y)
            }}
            let trimmed=cell.cropping(to:CGRect(x:minX,y:minY,width:max(1,maxX-minX+1),height:max(1,maxY-minY+1))) ?? cell
            result.append(UIImage(cgImage:trimmed))
        }
        return result
    }()

}

struct DressUpCanvas: View {
    let look: DressUpLook
    let title: String
    var showsLabels = true
    var poseRotation: Double = 0
    var poseLift: CGFloat = 0
    static let scenes = ["Spotlight", "Daydream", "Storybook", "Studio"]
    static let skin: [Color] = [.init(red:0.99,green:0.85,blue:0.73),.init(red:0.80,green:0.57,blue:0.40),.init(red:0.57,green:0.35,blue:0.23),.init(red:0.34,green:0.20,blue:0.15)]
    static let hair: [Color] = [.init(red:0.20,green:0.10,blue:0.07),.init(red:0.65,green:0.38,blue:0.16),.init(red:0.12,green:0.10,blue:0.14),.init(red:0.50,green:0.23,blue:0.41)]
    private var outfit: WardrobeItem { WardrobeItem.item(look.outfit) ?? WardrobeItem.all[0] }
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let skin = Self.skin[min(3,max(0,look.skin))]
            ZStack {
                scene(w:w,h:h)
                Group {
                Ellipse().fill(.black.opacity(0.11)).frame(width:w*0.34,height:h*0.025).position(x:w*0.5,y:h*0.915)
                Capsule().fill(skin.gradient).frame(width:w*0.065,height:h*0.065).position(x:w*0.5,y:h*0.322)
                // Clothing assets use a common full-canvas registration. No user photo enters generation.
                if let image = StyleArt.images[outfit.art] {
                    let neckY: CGFloat = outfit.art == "outfit-pop" ? 0.197 : outfit.art == "outfit-mint" ? 0.159 : outfit.art == "outfit-dress" ? 0.250 : 0.139
                    let scale: CGFloat = (0.90-0.325)/(0.98-neckY)
                    Image(uiImage:image).resizable().scaledToFit().hueRotation(.degrees(outfit.hue))
                        .frame(width:w*scale,height:h*scale).position(x:w*0.5,y:h*(0.325-neckY*scale+scale/2))
                }
                avatarFace(skin:skin).frame(width:w*(look.faceStyle == 1 ? 0.205 : 0.185),height:h*0.165)
                    .position(x:w*0.5,y:h*0.250).modifier(layer("face",w:w,h:h))
                if let image = StyleArt.images[WardrobeItem.item(look.hair)?.art ?? "hair-bob"] {
                    Image(uiImage:image).resizable().scaledToFit().hueRotation(.degrees(look.hairColor == 3 ? 290 : 0))
                        .brightness(look.hairColor == 1 ? 0.15 : look.hairColor == 2 ? -0.15 : 0)
                        .frame(width:w*0.33,height:w*0.33).position(x:w*0.5,y:h*0.228)
                        .mask {
                            Rectangle().overlay {
                                if look.hair == "waves" {
                                    Ellipse().frame(width:w*0.16,height:h*0.12).position(x:w*0.5,y:h*0.258).blendMode(.destinationOut)
                                }
                            }.compositingGroup()
                        }.modifier(layer("hair",w:w,h:h))
                }
                finishingTouches(w:w,h:h)
                accessory(w:w,h:h)
                if look.bag != "simple" {
                    let bagPosition=look.placement("bag")
                    Path { path in
                        path.move(to:CGPoint(x:w*0.41,y:h*0.36))
                        path.addLine(to:CGPoint(x:w*(0.66+bagPosition.x),y:h*(0.62+bagPosition.y)))
                    }.stroke(LinleyTheme.plum.opacity(0.6),style:StrokeStyle(lineWidth:w*0.012,lineCap:.round))
                    StyleCompanion(id:look.bag).frame(width:w*0.19,height:h*0.16).rotationEffect(.degrees(-8)).position(x:w*0.66,y:h*0.62)
                        .modifier(layer("bag",w:w,h:h))
                }
                }.rotationEffect(.degrees(poseRotation),anchor:.bottom).offset(y:poseLift)
                if showsLabels {VStack {
                    HStack {
                        Text("LINLEY / STYLE STUDIO").font(.system(size:max(7,w*0.021),weight:.bold,design:.rounded)).tracking(w*0.006)
                        Spacer()
                        Image(systemName:"sparkle")
                    }.foregroundStyle(LinleyTheme.plum.opacity(0.7))
                    Spacer()
                    Text(title.isEmpty ? outfit.title : title).font(.system(size:max(12,w*0.04),weight:.bold,design:.rounded)).foregroundStyle(LinleyTheme.plum)
                }.padding(w*0.05)}
            }.clipped()
        }.aspectRatio(2/3,contentMode:.fit)
            .accessibilityElement(children:.ignore).accessibilityLabel("Style preview: \(outfit.title), \(look.hair), \(Self.scenes[look.backdrop]) scene, skin tone \(look.skin+1), face style \(look.faceStyle+1), bag \(look.bag), lip color \(look.lipColor), eye shadow \(look.eyeShadow), blush \(look.blush)\(look.face != nil ? ", private photo avatar" : ", illustrated avatar")")
    }
    private func layer(_ id:String,w:CGFloat,h:CGFloat) -> StyleLayerPlacement {
        let centers:[String:UnitPoint] = ["face":.init(x:0.5,y:0.25),"hair":.init(x:0.5,y:0.228),"bag":.init(x:0.66,y:0.62),"glasses":.init(x:0.5,y:0.257),"makeup":.init(x:0.5,y:0.27),"accessory":.init(x:0.5,y:0.23),"ears":.init(x:0.5,y:0.17)]
        return StyleLayerPlacement(placement:look.placement(id),w:w,h:h,anchor:centers[id] ?? .center)
    }
    @ViewBuilder private func avatarFace(skin:Color) -> some View {
        ZStack {
            Ellipse().fill(skin.gradient)
            if let data=look.face {
                PrivateStyleFace(data:data).id(data)
            } else if look.faceStyle == 2 {
                illustratedFace(skin:skin)
            } else if StyleArt.faces.indices.contains(look.skin) {
                Image(uiImage:StyleArt.faces[look.skin]).resizable().scaledToFill()
            }
        }.clipShape(Ellipse())
    }
    private func scene(w:CGFloat,h:CGFloat) -> some View {
        let colors: [[Color]] = [[.init(red:0.91,green:0.87,blue:1),.init(red:1,green:0.93,blue:0.96)],
                                 [.init(red:0.86,green:0.97,blue:0.94),.init(red:1,green:0.90,blue:0.86)],
                                 [.init(red:0.87,green:0.94,blue:0.95),.init(red:0.96,green:0.92,blue:0.79)],
                                 [.init(red:0.98,green:0.94,blue:0.88),.white]]
        return ZStack {
            LinearGradient(colors:colors[look.backdrop],startPoint:.topLeading,endPoint:.bottomTrailing)
            RoundedRectangle(cornerRadius:w*0.45).fill(.white.opacity(0.48)).frame(width:w*0.78,height:h*0.82).position(x:w*0.5,y:h*0.51)
            ForEach(0..<12,id:\.self) { i in
                Image(systemName:look.backdrop == 2 ? "leaf.fill" : "sparkle")
                    .font(.system(size:w*CGFloat(i%3+1)*0.015)).foregroundStyle((look.backdrop == 2 ? LinleyTheme.mint : LinleyTheme.plum).opacity(0.20))
                    .position(x:w*(i%2 == 0 ? 0.10 : 0.90),y:h*(0.14+Double(i/2)*0.13))
            }
            Ellipse().fill(.white.opacity(0.6)).frame(width:w*0.62,height:h*0.055).position(x:w*0.5,y:h*0.915)
        }
    }
    private func illustratedFace(skin:Color) -> some View {
        GeometryReader { geo in
            let w=geo.size.width,h=geo.size.height
            ZStack {
                Ellipse().fill(LinearGradient(colors:[skin,skin.opacity(0.84)],startPoint:.topLeading,endPoint:.bottomTrailing))
                ForEach([-1.0,1.0],id:\.self) { side in
                    Ellipse().fill(Color.pink.opacity(0.19)).frame(width:w*0.21,height:h*0.11).position(x:w*(0.5+side*0.27),y:h*0.62)
                    Ellipse().fill(.white).frame(width:w*0.22,height:h*0.105).rotationEffect(.degrees(side*6)).position(x:w*(0.5+side*0.21),y:h*0.44)
                    Ellipse().fill(Color(red:0.20,green:0.12,blue:0.09)).frame(width:w*0.085,height:h*0.10).position(x:w*(0.5+side*0.21),y:h*0.44)
                    Circle().fill(.white).frame(width:w*0.028).position(x:w*(0.49+side*0.21),y:h*0.42)
                    Capsule().fill(Color.brown.opacity(0.8)).frame(width:w*0.20,height:h*0.02).rotationEffect(.degrees(side*9)).position(x:w*(0.5+side*0.21),y:h*0.33)
                }
                Ellipse().fill(skin.opacity(0.8)).frame(width:w*0.085,height:h*0.12).shadow(color:.brown.opacity(0.15),radius:1,x:1,y:1).position(x:w*0.5,y:h*0.59)
                Ellipse().fill(Color(red:0.62,green:0.25,blue:0.28)).frame(width:w*0.22,height:h*0.047).position(x:w*0.5,y:h*0.75)
            }
        }
    }
    @ViewBuilder private func finishingTouches(w:CGFloat,h:CGFloat) -> some View {
        Group {
            if look.makeup > 0 || look.blush > 0 {
                let index=look.blush > 0 ? look.blush : look.makeup
                let color:Color = index == 1 ? .orange : index == 2 ? .pink : .purple
                ForEach([-1.0,1.0],id:\.self) { side in
                    Ellipse().fill(color.opacity(0.28)).blur(radius:w*0.004).frame(width:w*0.035,height:h*0.013)
                        .position(x:w*(0.5+side*0.048),y:h*0.277)
                }
            }
            if look.lipColor > 0 {
                Ellipse().fill(palette(look.lipColor).opacity(0.60)).frame(width:w*0.030,height:h*0.006).position(x:w*0.5,y:h*0.299)
            }
            if look.eyeShadow > 0 {
                ForEach([-1.0,1.0],id:\.self) { side in
                    Ellipse().fill(palette(look.eyeShadow).opacity(0.38)).blur(radius:w*0.002).frame(width:w*0.033,height:h*0.006)
                        .rotationEffect(.degrees(side*8)).position(x:w*(0.5+side*0.035),y:h*0.247)
                }
            }
            if look.makeup == 3 {
                ForEach([-1.0,1.0],id:\.self) { side in
                    Image(systemName:"sparkle").font(.system(size:w*0.018)).foregroundStyle(.white.opacity(0.9)).position(x:w*(0.5+side*0.067),y:h*0.272)
                }
            }
        }.modifier(layer("makeup",w:w,h:h))
        if look.glasses > 0 {
            Group {
                ForEach([-1.0,1.0],id:\.self) { side in
                    if look.glasses == 1 {
                        Circle().fill(Color.cyan.opacity(0.10)).overlay(Circle().stroke(LinleyTheme.plum,lineWidth:w*0.004))
                            .frame(width:w*0.060,height:w*0.060).position(x:w*(0.5+side*0.037),y:h*0.257)
                    } else {
                        Image(systemName:"star.fill").font(.system(size:w*0.07)).foregroundStyle(LinleyTheme.plum.opacity(0.85))
                            .overlay(Image(systemName:"star").font(.system(size:w*0.07)).foregroundStyle(LinleyTheme.gold))
                            .position(x:w*(0.5+side*0.037),y:h*0.257)
                    }
                }
                Capsule().fill(LinleyTheme.plum).frame(width:w*0.02,height:h*0.0025).position(x:w*0.5,y:h*0.257)
            }.modifier(layer("glasses",w:w,h:h))
        }
        if look.animalEars {
            Group {
                ForEach([-1.0,1.0],id:\.self) { side in
                    Image(systemName:"triangle.fill").font(.system(size:w*0.065)).foregroundStyle(LinleyTheme.plum)
                        .overlay(Image(systemName:"triangle.fill").font(.system(size:w*0.041)).foregroundStyle(Color.pink))
                        .rotationEffect(.degrees(side*16)).position(x:w*(0.5+side*0.092),y:h*0.170)
                }
            }.modifier(layer("ears",w:w,h:h))
        }
    }
    private func palette(_ index:Int) -> Color { index == 1 ? .init(red:0.82,green:0.30,blue:0.21) : index == 2 ? .init(red:0.75,green:0.15,blue:0.36) : .init(red:0.48,green:0.20,blue:0.68) }
    @ViewBuilder private func accessory(w:CGFloat,h:CGFloat) -> some View {
        Group {
            if look.accessory == 1 || look.accessory == 2 {
                Image(systemName:look.accessory == 1 ? "star.fill" : "bowtie.fill").font(.system(size:w*0.045)).foregroundStyle(look.accessory == 1 ? LinleyTheme.gold : LinleyTheme.coralDeep)
                    .shadow(color:.white,radius:1).rotationEffect(.degrees(-18)).position(x:w*0.585,y:h*0.186)
            }
            if look.accessory == 3 {
                Path { p in p.addArc(center:CGPoint(x:w*0.5,y:h*0.239),radius:w*0.115,startAngle:.degrees(190),endAngle:.degrees(350),clockwise:false) }
                    .stroke(LinleyTheme.plum,style:StrokeStyle(lineWidth:w*0.014,lineCap:.round))
                ForEach([-1.0,1.0],id:\.self) {side in
                    RoundedRectangle(cornerRadius:w*0.014).fill(LinleyTheme.plum.gradient).overlay(RoundedRectangle(cornerRadius:w*0.014).stroke(.white.opacity(0.6),lineWidth:1))
                        .frame(width:w*0.028,height:h*0.039).position(x:w*(0.5+side*0.111),y:h*0.258)
                }
            }
        }.modifier(layer("accessory",w:w,h:h))
    }

}

/// Original vector companion bags; no brand characters or remote assets.
struct StyleCompanion: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            let w=geo.size.width, h=geo.size.height
            let color:Color = id == "bunny" ? Color(red:0.78,green:0.69,blue:0.95) : id == "bear" ? Color(red:0.85,green:0.64,blue:0.42) : id == "kitty" ? Color(red:0.63,green:0.87,blue:0.78) : Color(red:1,green:0.91,blue:0.75)
            ZStack {
                if id == "simple" {
                    Image(systemName:"sparkles").font(.system(size:min(w,h)*0.4)).foregroundStyle(LinleyTheme.plum.opacity(0.35)).position(x:w*0.5,y:h*0.5)
                } else {
                    RoundedRectangle(cornerRadius:w*0.12).stroke(color.opacity(0.8),lineWidth:w*0.06).frame(width:w*0.32,height:h*0.4).position(x:w*0.5,y:h*0.39)
                    ForEach([-1.0,1.0],id:\.self) { side in
                        if id == "bunny" {
                            Capsule().fill(color.gradient).overlay(Capsule().inset(by:w*0.035).fill(Color.pink.opacity(0.55))).frame(width:w*0.16,height:h*0.39)
                                .rotationEffect(.degrees(side*12)).position(x:w*(0.5+side*0.19),y:h*0.29)
                        } else if id == "bear" {
                            Circle().fill(color.gradient).overlay(Circle().inset(by:w*0.045).fill(Color.pink.opacity(0.4))).frame(width:w*0.23).position(x:w*(0.5+side*0.26),y:h*0.35)
                        } else if id == "kitty" {
                            Image(systemName:"triangle.fill").font(.system(size:w*0.31)).foregroundStyle(color).rotationEffect(.degrees(side*16)).position(x:w*(0.5+side*0.24),y:h*0.33)
                        }
                    }
                    RoundedRectangle(cornerRadius:w*0.29).fill(color.gradient).overlay(RoundedRectangle(cornerRadius:w*0.29).stroke(.white.opacity(0.7),lineWidth:w*0.015))
                        .frame(width:w*0.76,height:h*0.55).shadow(color:color.opacity(0.4),radius:w*0.04,y:w*0.035).position(x:w*0.5,y:h*0.60)
                    if id == "dumpling" {
                        ForEach(0..<5,id:\.self) { i in
                            Capsule().fill(Color.brown.opacity(0.16)).frame(width:w*0.025,height:h*0.11).rotationEffect(.degrees(Double(i-2)*12)).position(x:w*(0.34+Double(i)*0.08),y:h*0.40)
                        }
                    }
                    ForEach([-1.0,1.0],id:\.self) { side in
                        Circle().fill(LinleyTheme.plum).frame(width:w*0.045).overlay(Circle().fill(.white).frame(width:w*0.014).offset(x:-w*0.008,y:-w*0.008)).position(x:w*(0.5+side*0.13),y:h*0.56)
                        Ellipse().fill(Color.pink.opacity(0.42)).frame(width:w*0.12,height:h*0.045).position(x:w*(0.5+side*0.21),y:h*0.62)
                    }
                    Image(systemName:"heart.fill").font(.system(size:w*0.065)).foregroundStyle(LinleyTheme.coralDeep).position(x:w*0.5,y:h*0.64)
                    Capsule().fill(.white.opacity(0.6)).frame(width:w*0.35,height:h*0.016).position(x:w*0.5,y:h*0.78)
                }
            }
        }.accessibilityLabel(id == "simple" ? "No bag" : "\(id) companion bag")
    }
}

struct StyleLayerPlacement: ViewModifier {
    let placement:StylePlacement
    let w:CGFloat
    let h:CGFloat
    var anchor:UnitPoint = .center
    func body(content:Content) -> some View {
        content.frame(width:w,height:h)
            .scaleEffect(placement.scale,anchor:anchor)
            .rotationEffect(.degrees(placement.rotation),anchor:anchor)
            .offset(x:w*placement.x,y:h*placement.y)
    }
}

/// A view-scoped decoded photo avoids repeated allocation during poses and slider updates.
/// No global photo cache outlives this avatar view.
private struct PrivateStyleFace: View {
    @StateObject private var photo: PrivateFaceImage
    init(data:Data) {_photo=StateObject(wrappedValue:PrivateFaceImage(data:data))}
    var body: some View {
        Group {
            if let image=photo.image {Image(uiImage:image).resizable().scaledToFill()}
            else {Color.clear}
        }
    }
}
@MainActor private final class PrivateFaceImage: ObservableObject {
    let image: UIImage?
    init(data:Data) {image=UIImage(data:data)}
}
