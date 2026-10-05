import XCTest
import ManualTextProof
@testable import PersistenceProof

final class P4CaptureBindingTests:XCTestCase {
    func testTakeStoresExactDisplayedRevisionAndAliases() throws {
        let binding=try P4CaptureBinding.fixedPT()
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:1024)
        let snapshot=binding.snapshot(original);try snapshot.validate()
        XCTAssertEqual(Data(snapshot.revisions[0].text.utf8),Data(binding.revision.text.utf8))
        XCTAssertEqual(snapshot.takes[0].revisionID,snapshot.revisions[0].id)
        XCTAssertFalse(snapshot.takes[0].synthetic)
        XCTAssertEqual(binding.report["scriptSHA256"],binding.revision.identity.sha256)
        XCTAssertEqual(binding.report["persistenceRevisionAlias"],snapshot.takes[0].revisionID)
        XCTAssertEqual(snapshot.originals,[original])
    }
    func testDifferentLanguageOrEditedBytesCannotReplaceFixedTake() throws {
        XCTAssertThrowsError(try P4CaptureBinding(revision:Fixtures.make(language:.enUS,long:true)))
        let fixed=try Fixtures.make(language:.ptBR,long:true)
        let changed=try ScriptRevision(scriptID:fixed.identity.scriptID,revisionID:fixed.identity.revisionID,language:.ptBR,text:fixed.text+" ")
        XCTAssertThrowsError(try P4CaptureBinding(revision:changed))
    }
    func testReopenBindingRequiresExactBytesAfterStoreRoundTrip() throws {
        let binding=try P4CaptureBinding.fixedPT()
        let bytes=Fixture.original
        let original=Original(id:"O",sha256:SHA256.hex(bytes),byteCount:bytes.count)
        let snapshot=binding.snapshot(original)
        let parent=FileManager.default.temporaryDirectory.appendingPathComponent("p4-binding-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:parent,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:parent) }
        let store=Store(parent.appendingPathComponent("project"))
        try store.commit(snapshot,payloads:["O":bytes])
        let (reopened,originals)=try store.load()
        XCTAssertTrue(binding.matches(reopened));XCTAssertEqual(originals["O"],bytes)
        let normalized=binding.revision.text.precomposedStringWithCanonicalMapping
        XCTAssertEqual(normalized,binding.revision.text)
        XCTAssertNotEqual(Data(normalized.utf8),Data(binding.revision.text.utf8))
        var changed=reopened
        changed.revisions=[Revision(id:"R1",scriptID:"S",text:normalized)]
        XCTAssertFalse(binding.matches(changed))
    }
    func testNewScopeDoesNotEnableHistoricalAttempts() {
        let new=P3AttemptScope.cameraSettings
        XCTAssertTrue(new.allowsCapture);XCTAssertTrue(new.requiresInstructions);XCTAssertTrue(new.requiresPreview)
        XCTAssertEqual(new.axis,.vertical)
        let root=URL(fileURLWithPath:"/synthetic/P3CaptureSandbox")
        XCTAssertEqual(new.base(in:root).lastPathComponent,"P4-CAMERA-SETTINGS-001")
        for old in [P3AttemptScope.original,.retry001,.retry002,.vertical,.horizontal,.horizontalResume,.manualTextVertical,.manualTextFrontVertical] {
            XCTAssertFalse(old.allowsCapture);XCTAssertNotEqual(old.base(in:root),new.base(in:root))
        }
        var consent=P3PreparationConsent(scope:new)
        XCTAssertFalse(consent.mayPrepare(phase:.idle));consent.acknowledgeInstructions()
        XCTAssertTrue(consent.mayPrepare(phase:.idle))
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
        consent.observePreview(ready:true)
        XCTAssertTrue(consent.confirmPreview(phase:.ready,sessionRunning:true,humanVisible:true))
        XCTAssertTrue(consent.mayRecord(phase:.ready,sessionRunning:true))
        consent.observePreview(ready:false)
        XCTAssertFalse(consent.mayRecord(phase:.ready,sessionRunning:true))
    }
}
