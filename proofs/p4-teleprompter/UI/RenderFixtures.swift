// Offline synthetic renderer only. No app lifecycle, sensors or device deployment.
import SwiftUI
import AppKit
import ManualTextProof

@main struct RenderFixtures {
    @MainActor static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Specify a private output directory") }
        let destination=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
        try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)
        for language in [Language.ptBR,.enUS] { for long in [false,true] {
            let revision=try Fixtures.make(language:language,long:long)
            for (width,height) in [(390,844),(844,390),(1024,768)] { for font in [22,36] {
                let name="\(language.rawValue)-\(long ? "long" : "short")-\(width)x\(height)-\(font).png"
                let renderer=ImageRenderer(content:VStack(alignment:.leading,spacing:12) {
                    Text("STATIC TEXT ONLY / scroll NOT PROVEN").font(.caption)
                    FixtureTextBlock(text:revision.blocks[0].text,fontSize:CGFloat(font))
                    Spacer(minLength:0)
                }.padding(16).frame(width:CGFloat(width),height:CGFloat(height),alignment:.topLeading).clipped().background(Color.white).foregroundStyle(Color.black))
                renderer.scale=1
                guard let image=renderer.cgImage else { throw NSError(domain:"P4Render",code:1) }
                let representation=NSBitmapImageRep(cgImage:image)
                guard image.width==width,image.height==height,let png=representation.representation(using:.png,properties:[:]) else { throw NSError(domain:"P4Render",code:2) }
                try png.write(to:destination.appendingPathComponent(name),options:.withoutOverwriting)
                print("\(name) \(image.width)x\(image.height) revision=\(revision.identity.sha256)")
            }}
        }}
    }
}
