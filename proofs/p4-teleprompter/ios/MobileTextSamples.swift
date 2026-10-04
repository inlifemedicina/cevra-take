import SwiftUI
import ManualTextProof

// Pure text surface: no capture controller, AVFoundation, permission or file operations.
struct P4MobileTextSamples:View {
    @State private var language=Language.ptBR
    private let revisions:[Language:ScriptRevision]
    init(language:Language = .ptBR) {
        _language=State(initialValue:language)
        revisions=Dictionary(uniqueKeysWithValues:[Language.ptBR,.enUS].compactMap { language in
            (try? Fixtures.make(language:language,long:true)).map { (language,$0) }
        })
    }
    var body:some View {
        VStack(spacing:12) {
            Text("P4 — amostras de toque, sem sensores").font(.headline)
            Picker("Idioma da amostra",selection:$language) {
                Text("Português").tag(Language.ptBR);Text("English").tag(Language.enUS)
            }.pickerStyle(.segmented)
            if let revision=revisions[language] {
                ManualPrompter(revision:revision,fontSize:22).id(language)
            } else { Text("BLOCKED — fixture indisponível") }
        }.padding()
    }
}
