import XCTest
@testable import ManualTextProof

final class ReadingTests:XCTestCase {
    func fixture() throws -> ScriptRevision { try Fixtures.make(language:.ptBR,long:true) }
    func testExactBytesOverrideCanonicalStringEquality() throws {
        let a=try ScriptRevision(scriptID:"S",revisionID:"R",language:.ptBR,text:"café")
        let b=try ScriptRevision(scriptID:"S",revisionID:"R",language:.ptBR,text:"cafe\u{301}")
        XCTAssertEqual(a.text,b.text)
        XCTAssertNotEqual(a.identity,b.identity)
        XCTAssertThrowsError(try ReadingState(revision:b,checkpoint:ReadingState(revision:a).checkpoint))
    }
    func testAllFixturesReconstructExactUTF8WithoutSplittingGraphemes() throws {
        for language in [Language.ptBR,.enUS] { for long in [false,true] {
            let r=try Fixtures.make(language:language,long:long)
            XCTAssertEqual(Array(r.blocks.map(\.text).joined().utf8),Array(r.text.utf8))
            var offset=0
            for block in r.blocks { XCTAssertEqual(block.start,offset);XCTAssertLessThanOrEqual(block.text.count,120);offset += block.text.count }
            XCTAssertEqual(offset,r.characterCount)
            XCTAssertTrue(r.text.contains("cafe\u{301}"))
        }}
    }
    func testPauseResumeRetainsManualPointAndRevision() throws {
        let r=try fixture();var s=ReadingState(revision:r)
        try s.apply(s.command(.select(121)));let checkpoint=s.checkpoint
        try s.apply(s.command(.resume));try s.apply(s.command(.pause));try s.apply(s.command(.resume))
        XCTAssertEqual(s.checkpoint.identity,checkpoint.identity);XCTAssertEqual(s.position,121)
        XCTAssertEqual(s.generation,4)
    }
    func testDuplicateStaleFutureAndForeignCommandsDoNotMutate() throws {
        let r=try fixture();var s=ReadingState(revision:r)
        let command=s.command(.select(120));try s.apply(command)
        let checkpoint=s.checkpoint;let generation=s.generation
        let foreign=ReadingState(revision:r)
        let other=try Fixtures.make(language:.enUS,long:true)
        for rejected in [command,foreign.command(.resume),ManualCommand(identity:r.identity,session:s.session,generation:99,action:.select(240)),ManualCommand(identity:other.identity,session:s.session,generation:s.generation,action:.select(240))] {
            XCTAssertThrowsError(try s.apply(rejected))
            XCTAssertEqual(s.checkpoint.identity,checkpoint.identity);XCTAssertEqual(s.position,checkpoint.position);XCTAssertEqual(s.generation,generation)
        }
    }
    func testInvalidPositionsAndTransitionsDoNotConsumeGeneration() throws {
        var s=ReadingState(revision:try fixture())
        for action in [ManualAction.select(-1),.select(s.revision.characterCount+1),.select(0),.pause] {
            XCTAssertThrowsError(try s.apply(s.command(action)));XCTAssertEqual(s.generation,0);XCTAssertEqual(s.position,0);XCTAssertEqual(s.phase,.paused)
        }
        try s.apply(s.command(.select(s.revision.characterCount)))
        XCTAssertEqual(s.position,s.revision.characterCount)
    }
    func testCheckpointRoundTripRestoresPausedWithFreshSession() throws {
        let r=try fixture();var s=ReadingState(revision:r)
        try s.apply(s.command(.select(240)));try s.apply(s.command(.resume))
        let old=s.command(.select(360))
        let decoded=try JSONDecoder().decode(ReadingCheckpoint.self,from:JSONEncoder().encode(s.checkpoint))
        var restored=try ReadingState(revision:r,checkpoint:decoded)
        XCTAssertEqual(restored.position,240);XCTAssertEqual(restored.phase,.paused);XCTAssertNotEqual(restored.session,s.session)
        XCTAssertThrowsError(try restored.apply(old));XCTAssertEqual(restored.position,240)
        XCTAssertThrowsError(try ReadingState(revision:r,checkpoint:ReadingCheckpoint(identity:r.identity,position:-1)))
        let changed=try ScriptRevision(scriptID:r.identity.scriptID,revisionID:r.identity.revisionID,language:.enUS,text:r.text)
        XCTAssertThrowsError(try ReadingState(revision:changed,checkpoint:decoded))
    }
    func testContainmentRejectsInvalidFixtures() throws {
        for text in ["",String(repeating:"a",count:20_001),String(repeating:"👩🏽‍⚕️",count:20_000)] {
            XCTAssertThrowsError(try ScriptRevision(scriptID:"S",revisionID:"R",language:.ptBR,text:text))
        }
        for id in ["","../S","S é",String(repeating:"A",count:65)] {
            XCTAssertThrowsError(try ScriptRevision(scriptID:id,revisionID:"R",language:.ptBR,text:"ok"))
        }
    }
}
