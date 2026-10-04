import SwiftUI
import ManualTextProof

@MainActor
public struct ManualPrompter:View {
    @State private var reading:ReadingState
    @State private var error=""
    private let fontSize:CGFloat
    public init(revision:ScriptRevision,fontSize:CGFloat=22) {
        _reading=State(initialValue:ReadingState(revision:revision));self.fontSize=fontSize
    }
    private var portuguese:Bool { reading.revision.identity.language == .ptBR }
    private func apply(_ action:ManualAction) {
        do { try reading.apply(reading.command(action));error="" }
        catch { self.error=portuguese ? "Comando rejeitado; ponto preservado" : "Command rejected; reading point preserved" }
    }
    public var body:some View {
        VStack(alignment:.leading,spacing:12) {
            Text(portuguese ? "P4 — fixture sintética / leitura manual" : "P4 — synthetic fixture / manual reading").font(.headline)
            Text("\(reading.revision.identity.scriptID)/\(reading.revision.identity.revisionID) · \(reading.position)/\(reading.revision.characterCount) · \(reading.phase == .paused ? "PAUSED" : "READING")").font(.caption)
            HStack {
                Button(portuguese ? "Pausar" : "Pause") { apply(.pause) }.disabled(reading.phase == .paused)
                Button(portuguese ? "Retomar" : "Resume") { apply(.resume) }.disabled(reading.phase == .reading)
            }
            ScrollViewReader { proxy in
                Button(portuguese ? "Voltar ao ponto marcado" : "Return to marked point") {
                    let anchor=reading.revision.blocks.last(where:{$0.start<=reading.position})?.start ?? 0
                    proxy.scrollTo(anchor,anchor:.top) // human command, no timer or on-change scrolling
                }
                ScrollView {
                    VStack(alignment:.leading,spacing:16) {
                        ForEach(reading.revision.blocks) { block in
                            VStack(alignment:.leading) {
                                FixtureTextBlock(text:block.text,fontSize:fontSize)
                                Button(portuguese ? "Marcar ponto \(block.start)" : "Mark point \(block.start)") { apply(.select(block.start)) }
                                    .font(.caption).disabled(reading.position==block.start)
                            }.id(block.start).frame(maxWidth:.infinity,alignment:.leading)
                        }
                    }.padding(8)
                }
            }
            if !error.isEmpty { Text(error).font(.caption) }
        }.padding(16).background(Color.white).foregroundStyle(Color.black)
    }
}

// Same text primitive as the manual UI; static renderer does not simulate ScrollView.
public struct FixtureTextBlock:View {
    public let text:String
    public let fontSize:CGFloat
    public var body:some View { Text(text).font(.system(size:fontSize)).fixedSize(horizontal:false,vertical:true) }
}
