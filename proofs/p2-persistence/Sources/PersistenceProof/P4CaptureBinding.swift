import Foundation
import ManualTextProof

public enum P4CaptureError:Error { case notProtocolRevision }
// A fixed protocol binding. UI commands cannot replace the captured revision.
public struct P4CaptureBinding:Sendable {
    public let revision:ScriptRevision
    public init(revision:ScriptRevision) throws {
        let expected=try Fixtures.make(language:.ptBR,long:true)
        guard revision.identity==expected.identity,
              Data(revision.text.utf8)==Data(expected.text.utf8) else { throw P4CaptureError.notProtocolRevision }
        self.revision=revision
    }
    public static func fixedPT() throws -> Self {
        try Self(revision:Fixtures.make(language:.ptBR,long:true))
    }
    // Existing persistence proof IDs are aliases; preserve exact displayed text.
    public func snapshot(_ original:Original)->Snapshot {
        Snapshot(formatVersion:1,projectID:"P3-CAPTURE-001",
            revisions:[Revision(id:"R1",scriptID:"S",text:revision.text)],
            takes:[Take(id:"T",revisionID:"R1",originalID:"O",synthetic:false)],originals:[original])
    }
    public func matches(_ snapshot:Snapshot)->Bool {
        guard snapshot.originals.count==1,snapshot.revisions.count==1 else { return false }
        return snapshot==self.snapshot(snapshot.originals[0]) &&
            Data(snapshot.revisions[0].text.utf8)==Data(revision.text.utf8)
    }
    public var report:[String:String] {
        ["p4Protocol":"P4-MANUAL-TEXT-001","scriptID":revision.identity.scriptID,
         "scriptRevision":revision.identity.revisionID,"scriptLanguage":revision.identity.language.rawValue,
         "scriptSHA256":revision.identity.sha256,"persistenceScriptAlias":"S","persistenceRevisionAlias":"R1"]
    }
}
