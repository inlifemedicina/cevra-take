import Foundation
import CryptoKit

public enum ProofError:Error { case invalidRevision, stale, invalidPosition, invalidTransition }
public enum Language:String,Codable,Sendable { case ptBR="pt-BR",enUS="en-US" }
public struct TextIdentity:Equatable,Codable,Sendable {
    public let scriptID:String,revisionID:String,sha256:String
    public let language:Language
}
public struct TextBlock:Identifiable,Sendable {
    public let start:Int,text:String
    public var id:Int { start }
}
public struct ScriptRevision:Sendable {
    public let identity:TextIdentity,text:String
    public var characterCount:Int { text.count }
    public init(scriptID:String,revisionID:String,language:Language,text:String) throws {
        func validID(_ s:String)->Bool {
            !s.isEmpty && s.utf8.count<=64 && s.unicodeScalars.allSatisfy {
                (65...90).contains($0.value) || (97...122).contains($0.value) || (48...57).contains($0.value) || $0 == "-" || $0 == "_"
            }
        }
        guard validID(scriptID),validID(revisionID),!text.isEmpty,text.utf8.count<=200_000,text.count<=20_000 else { throw ProofError.invalidRevision }
        self.text=text
        self.identity=TextIdentity(scriptID:scriptID,revisionID:revisionID,
            sha256:SHA256.hash(data:Data(text.utf8)).map { String(format:"%02x",$0) }.joined(),language:language)
    }
    public var blocks:[TextBlock] {
        let characters=Array(text)
        var result:[TextBlock]=[]
        var start=0
        while start<characters.count {
            var end=min(start+120,characters.count)
            if end<characters.count, !characters[end].isWhitespace,
               let separator=characters[start..<end].lastIndex(where: { $0.isWhitespace }) {
                end=separator+1
            }
            result.append(TextBlock(start:start,text:String(characters[start..<end])))
            start=end
        }
        return result
    }
}
public enum ReadingPhase:Sendable { case paused,reading }
public enum ManualAction:Sendable { case pause,resume,select(Int) }
public struct ManualCommand:Sendable {
    public let identity:TextIdentity,session:UUID,generation:UInt64,action:ManualAction
    public init(identity:TextIdentity,session:UUID,generation:UInt64,action:ManualAction) {
        self.identity=identity;self.session=session;self.generation=generation;self.action=action
    }
}
public struct ReadingCheckpoint:Codable,Sendable {
    public let identity:TextIdentity,position:Int
    public init(identity:TextIdentity,position:Int) { self.identity=identity;self.position=position }
}
public struct ReadingState:Sendable {
    public let revision:ScriptRevision
    public let session=UUID()
    public private(set) var generation:UInt64=0
    public private(set) var position=0
    public private(set) var phase=ReadingPhase.paused
    public init(revision:ScriptRevision) { self.revision=revision }
    public init(revision:ScriptRevision,checkpoint:ReadingCheckpoint) throws {
        guard checkpoint.identity==revision.identity else { throw ProofError.stale }
        guard (0...revision.characterCount).contains(checkpoint.position) else { throw ProofError.invalidPosition }
        self.revision=revision;self.position=checkpoint.position
    }
    public var checkpoint:ReadingCheckpoint { ReadingCheckpoint(identity:revision.identity,position:position) }
    public func command(_ action:ManualAction)->ManualCommand {
        ManualCommand(identity:revision.identity,session:session,generation:generation,action:action)
    }
    public mutating func apply(_ command:ManualCommand) throws {
        guard command.identity==revision.identity,command.session==session,command.generation==generation,generation<UInt64.max else { throw ProofError.stale }
        switch command.action {
        case .pause:guard phase == .reading else { throw ProofError.invalidTransition };phase = .paused
        case .resume:guard phase == .paused else { throw ProofError.invalidTransition };phase = .reading
        case .select(let p):
            guard (0...revision.characterCount).contains(p),p != position else { throw ProofError.invalidPosition };position=p
        }
        generation += 1
    }
}
public enum Fixtures {
    public static func make(language:Language,long:Bool) throws -> ScriptRevision {
        let sample=language == .ptBR ? "Texto sintético: ação, café, cafe\u{301}, € — 👩🏽‍⚕️.\nExplicar uma ideia com clareza, sem dados reais.\n" : "Synthetic text: clarity, café, cafe\u{301}, € — 👨‍👩‍👧‍👦.\nExplain one idea; no real personal data.\n"
        return try ScriptRevision(scriptID:language == .ptBR ? "PT" : "EN",revisionID:long ? "LONG_R1" : "SHORT_R1",language:language,text:String(repeating:sample,count:long ? 100 : 1))
    }
}
