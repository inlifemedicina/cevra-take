import XCTest
@testable import ManualTextProof

final class WordBoundaryTests:XCTestCase {
    func revision(_ text:String) throws -> ScriptRevision {
        try ScriptRevision(scriptID:"BOUNDARY",revisionID:"R1",language:.ptBR,text:text)
    }

    func testOrdinaryWordsDoNotSplitAcrossBlocksAndWhitespaceIsPreserved() throws {
        let whitespace=String(repeating:"  alpha\tbeta gamma\r\ndelta epsilon  ",count:20)
        let fixtures=[try Fixtures.make(language:.ptBR,long:true),
                      try Fixtures.make(language:.enUS,long:true),try revision(whitespace)]
        for r in fixtures {
            let blocks=r.blocks
            XCTAssertEqual(Array(blocks.map(\.text).joined().utf8),Array(r.text.utf8))
            let split=zip(blocks,blocks.dropFirst()).first { left,right in
                !left.text.last!.isWhitespace && !right.text.first!.isWhitespace
            }
            XCTAssertNil(split,"Ordinary word split at logical ordinal \(split?.1.start ?? -1)")
        }
    }

    func testLongUnbrokenGraphemeTokenMakesBoundedProgressWithoutLoss() throws {
        let token=String(repeating:"👩🏽‍⚕️",count:125)
        let r=try revision(token)
        let blocks=r.blocks
        XCTAssertEqual(blocks.map { $0.text.count },[120,5])
        XCTAssertEqual(blocks.map(\.start),[0,120])
        XCTAssertEqual(Array(blocks.map(\.text).joined().utf8),Array(token.utf8))
    }

    func testUnicodeLayoutKeepsExactBytesRevisionAndLogicalCursor() throws {
        let text=String(repeating:" \tAção cafe\u{301} 👩🏽‍⚕️ 👨‍👩‍👧‍👦 \r\n",count:20)
        let r=try revision(text)
        var reading=ReadingState(revision:r)
        try reading.apply(reading.command(.select(121)))
        try reading.apply(reading.command(.resume))
        let identity=r.identity
        let checkpoint=reading.checkpoint
        let generation=reading.generation
        let phase=reading.phase
        let blocks=reading.revision.blocks
        var position=0
        for block in blocks {
            XCTAssertEqual(block.start,position)
            XCTAssertFalse(block.text.isEmpty)
            XCTAssertLessThanOrEqual(block.text.count,120)
            position += block.text.count
        }
        XCTAssertEqual(position,r.characterCount)
        XCTAssertEqual(Array(blocks.map(\.text).joined().utf8),Array(text.utf8))
        XCTAssertEqual(reading.revision.identity,identity)
        XCTAssertEqual(reading.checkpoint.identity,checkpoint.identity)
        XCTAssertEqual(reading.position,checkpoint.position)
        XCTAssertEqual(reading.generation,generation)
        XCTAssertEqual(reading.phase,phase)
        let restored=try ReadingState(revision:r,checkpoint:checkpoint)
        XCTAssertEqual(restored.position,121)
        XCTAssertEqual(restored.revision.identity,identity)
    }
}
