import Foundation
import XCTest
@testable import PersistenceProof

final class P4CadenceTests: XCTestCase {
    private func timeline(_ samples:[P4CadenceSample]?=nil,end:Int64=18000,scale:Int64=600,q:Int64=1)->P4CadenceTimeline {
        .init(scale:scale,quantum:q,end:end,samples:samples ?? (0..<900).map { .init(start:Int64($0)*20,duration:20) })
    }
    private func check(_ t:P4CadenceTimeline,configured:Int=30,applied:Int?=30)->P4CadenceResult {
        P4Cadence.evaluate(t,configuredFPS:configured,appliedFPS:applied)
    }
    func testExactCadenceAndNativeApplied30() {
        let result=check(timeline());XCTAssertEqual(result.status,.pass);XCTAssertEqual(result.samples,900)
        XCTAssertEqual(result.averageFPS,30)
        XCTAssertEqual(check(timeline(),applied:nil).status,.fail)
        XCTAssertEqual(check(timeline(),applied:29).status,.fail)
        XCTAssertEqual(check(timeline(),configured:60,applied:60).status,.unavailable)
    }
    func testPositiveAndNegativeOneTickQuantizationBoundaries() {
        for shift:Int64 in [-1,1] {
            var samples=(0..<900).map { P4CadenceSample(start:Int64($0)*20+($0>=400 ? shift:0),duration:20) }
            samples[399] = .init(start:samples[399].start,duration:20+shift)
            let result=check(timeline(samples,end:18000+shift))
            XCTAssertEqual(result.status,.pass);XCTAssertNotEqual(result.averageFPS,30)
        }
    }
    func testRepresentableMissingFrameGapFailsDespiteNearTargetAverage() {
        var samples=timeline().samples;samples.remove(at:400)
        XCTAssertEqual(check(timeline(samples)).reason,"frameInterval")
    }
    func testDuplicateAndBackwardPresentationStartsFail() {
        var duplicate=timeline().samples;duplicate[400]=duplicate[399]
        XCTAssertEqual(check(timeline(duplicate)).reason,"nonMonotonicPTS")
        var reversed=timeline().samples;reversed.swapAt(399,400)
        XCTAssertEqual(check(timeline(reversed)).status,.fail)
    }
    func testAccumulatedTwoTickDriftFailsEvenWithAllowedLocalIntervals() {
        let samples=(0..<900).map { i in P4CadenceSample(start:Int64(i)*20+(i>=300 ? 1:0)+(i>=600 ? 1:0),duration:20) }
        XCTAssertEqual(check(timeline(samples,end:18002)).reason,"accumulatedPhase")
    }
    func testTwoTickLocalDeviationFails() {
        let samples=(0..<900).map { i in P4CadenceSample(start:Int64(i)*20+(i>=400 ? 2:0),duration:20) }
        XCTAssertEqual(check(timeline(samples,end:18002)).reason,"frameInterval")
    }
    func testEditedPartialFirstAndLastSamplesAndTrimmedSamples() {
        let samples=[P4CadenceSample(start:-39,duration:20),.init(start:-19,duration:20),
                     .init(start:1,duration:20),.init(start:21,duration:20),.init(start:41,duration:20),.init(start:61,duration:20)]
        let result=check(timeline(samples,end:60))
        XCTAssertEqual(result.status,.pass);XCTAssertEqual(result.samples,4)
    }
    func testInitialMissingCoverageAndMissingFinalCoverageFail() {
        let missingFirst=Array(timeline().samples.dropFirst())
        XCTAssertEqual(check(timeline(missingFirst)).status,.fail)
        let missingLast=Array(timeline().samples.dropLast())
        XCTAssertEqual(check(timeline(missingLast)).status,.fail)
    }
    func testOneTickTailCoverageAllowedTwoTicksDenied() {
        XCTAssertEqual(check(timeline(end:18001)).status,.pass)
        XCTAssertEqual(check(timeline(end:18002)).reason,"uncoveredTail")
    }
    func testStretchedLastSampleCannotHideMissingFinalSecond() {
        var samples=Array(timeline().samples.prefix(870))
        samples[869] = .init(start:samples[869].start,duration:1000)
        XCTAssertEqual(check(timeline(samples,end:17957)).status,.fail)
    }
    func testUnsupportedCoarseClockAndInsufficientSamplesNeverPass() {
        XCTAssertEqual(check(timeline(scale:60,q:1)).status,.unavailable)
        XCTAssertEqual(check(timeline([.init(start:0,duration:20)],end:20)).reason,"tooFewPresentedSamples")
        XCTAssertEqual(check(timeline([],end:20)).status,.unavailable)
        XCTAssertEqual(P4Cadence.evaluate(nil,configuredFPS:30,appliedFPS:30).status,.unavailable)
        XCTAssertEqual(check(timeline(end:2,scale:61,q:1)).status,.unavailable) // no two presented starts
    }
    func testMalformedOrUnboundedTimingNeverOverflowsOrPasses() {
        for t in [timeline(scale:Int64.max),timeline(q:Int64.max),timeline([.init(start:Int64.max,duration:20)],end:20),
                  timeline([.init(start:0,duration:0),.init(start:20,duration:20)],end:40),
                  timeline(Array(repeating:.init(start:0,duration:20),count:4097))] {
            XCTAssertEqual(check(t).status,.unavailable)
        }
    }
    func testGeometryDurationAudioAndSDRStillRequired() {
        let mode=P4VideoMode(width:1920,height:1080,fps:30),pass=check(timeline())
        func profile(_ seconds:Double=30,_ width:Int=1920,_ height:Int=1080,_ videos:Int=1,_ audio:Int=1,_ sdr:Bool=true,cadence:P4CadenceResult?=nil)->P3StoredProfileFeedback {
            mode.cadenceProfile(duration:seconds,width:width,height:height,videoTracks:videos,audioTracks:audio,sdr:sdr,cadence:cadence ?? pass)
        }
        XCTAssertEqual(profile(),.pass);XCTAssertEqual(profile(29,1080,1920),.pass);XCTAssertEqual(profile(31),.pass)
        for value in [profile(28.999),profile(31.001),profile(.nan),profile(30,1280,720),profile(30,1920,1080,2),profile(30,1920,1080,1,0),profile(30,1920,1080,1,1,false)] { XCTAssertEqual(value,.fail) }
        XCTAssertEqual(profile(cadence:.init(.unavailable,"missing")),.unavailable)
        XCTAssertEqual(profile(cadence:.init(.fail,"gap")),.fail)
        XCTAssertEqual(P4VideoMode(width:1920,height:1080,fps:60).cadenceProfile(duration:30,width:1920,height:1080,videoTracks:1,audioTracks:1,sdr:true,cadence:pass),.unavailable)
    }
    func testHistoricalNominalCriteriaAndRecordedFailRemainUnchanged() {
        let mean=540000.0/18001
        XCTAssertFalse(P3Limits.fileProfile(duration:30,width:1920,height:1080,fps:mean,videoTracks:1,audioTracks:1,sdrVerified:true))
        XCTAssertFalse(P4VideoMode(width:1920,height:1080,fps:30).fileProfile(duration:30,width:1920,height:1080,fps:mean,videoTracks:1,audioTracks:1,sdr:true))
        let original=Original(id:"O",sha256:String(repeating:"a",count:64),byteCount:123)
        var report=["sha256":original.sha256,"bytes":"123","profile":"FAIL","nominalFPS":String(mean)]
        let old=P3FileFeedback.recorded(report,matching:original)
        XCTAssertEqual(old.profile,.fail);XCTAssertNil(old.independentlyMeasuredAverageFPS)
        report.merge(P4CadenceResult(.pass,"oneTickContinuity",averageFPS:29.9983,samples:900).report) { _,new in new }
        XCTAssertEqual(P3FileFeedback.recorded(report,matching:original).profile,.fail)
        XCTAssertEqual(P3FileFeedback.recorded(report,matching:original).independentlyMeasuredAverageFPS,29.9983)
        report["profileCriteriaVersion"]="futureUnknown"
        XCTAssertNil(P3FileFeedback.recorded(report,matching:original).independentlyMeasuredAverageFPS)
    }

    private func u(_ value:Int64,_ count:Int=4)->Data {
        let value=UInt64(bitPattern:value)
        return Data((0..<count).reversed().map { UInt8(truncatingIfNeeded:value>>($0*8)) })
    }
    private func box(_ type:String,_ payload:Data)->Data { u(Int64(payload.count+8))+Data(type.utf8)+payload }
    private func header(scale:Int64,duration:Int64)->Data { Data(repeating:0,count:12)+u(scale)+u(duration) }
    private func moov(deltas:[Int64]=Array(repeating:20,count:900),offsets:[Int64]?=nil,edit:(Int64,Int64,Int64)?=(17957,0,600),rate:Int64=1,videoScale:Int64=600)->Data {
        let n=Int64(deltas.count),mediaDuration=deltas.reduce(0,+)
        let stts=box("stts",Data(repeating:0,count:4)+u(n)+deltas.reduce(Data()) { $0+u(1)+u($1) })
        var tables=stts+box("stsz",Data(repeating:0,count:4)+u(1)+u(n))
        if let offsets { tables+=box("ctts",Data([1,0,0,0])+u(Int64(offsets.count))+offsets.reduce(Data()) { $0+u(1)+u($1) }) }
        let mdia=box("mdhd",header(scale:videoScale,duration:mediaDuration))+box("hdlr",Data(repeating:0,count:8)+Data("vide".utf8))+box("minf",box("stbl",tables))
        let edits=edit.map { box("edts",box("elst",Data(repeating:0,count:4)+u(1)+u($0.0)+u($0.1)+u(rate,2)+u(0,2))) } ?? Data()
        return box("mvhd",header(scale:edit?.2 ?? videoScale,duration:edit?.0 ?? mediaDuration))+box("trak",edits+box("mdia",mdia))
    }
    func testMOVOneTickCadenceWithEditedTailAndDifferentDuration() throws {
        var deltas=Array(repeating:Int64(20),count:900);deltas[400]=21
        let t=try P4CadenceMOV.parse(moov:moov(deltas:deltas))
        XCTAssertEqual(t.scale,600);XCTAssertEqual(t.end,17957);XCTAssertEqual(t.samples.count,900)
        let result=check(t);XCTAssertEqual(result.status,.pass);XCTAssertEqual(result.samples,898)
        XCTAssertLessThan(try XCTUnwrap(result.averageFPS),30)
    }
    func testCompositionOffsetsReorderDecodeSequenceIntoPresentationOrder() throws {
        let t=try P4CadenceMOV.parse(moov:moov(deltas:[20,20,20,20],offsets:[0,20,-20,0],edit:(80,0,600)))
        XCTAssertEqual(t.samples.map(\.start),[0,20,40,60]);XCTAssertEqual(check(t).status,.pass)
        let duplicate=try P4CadenceMOV.parse(moov:moov(deltas:[20,20,20,20],offsets:[0,0,-20,0],edit:(80,0,600)))
        XCTAssertEqual(check(duplicate).reason,"nonMonotonicPTS")
    }
    func testDifferentMovieAndMediaClocksUseExactCommonGrid() throws {
        let t=try P4CadenceMOV.parse(moov:moov(edit:(30000,0,1000)))
        XCTAssertEqual(t.scale,3000);XCTAssertEqual(t.quantum,5);XCTAssertEqual(t.end,90000)
        XCTAssertEqual(check(t).status,.pass)
    }
    func testMediaOffsetEditAllowsPartialBoundaries() throws {
        let t=try P4CadenceMOV.parse(moov:moov(deltas:[20,20,20,20,20],edit:(60,19,600)))
        XCTAssertEqual(check(t).status,.pass);XCTAssertEqual(check(t).samples,4)
    }
    func testUnsupportedEditRateNegativeMediaStartAndMalformedCountsNeverPass() {
        for data in [moov(rate:2),moov(edit:(17957,-1,600)),moov(deltas:[20,0,20]),moov(offsets:[0,0]),Data([0,0,0,3]),moov(deltas:Array(repeating:20,count:4097))] {
            XCTAssertThrowsError(try P4CadenceMOV.parse(moov:data))
        }
    }
    func testMetadataOnlyReaderSkipsPayloadAndDoesNotMutateSyntheticInput() throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true);defer { try? FileManager.default.removeItem(at:folder) }
        let file=folder.appendingPathComponent("synthetic.mov")
        let data=box("ftyp",Data(repeating:0,count:16))+box("mdat",Data(repeating:0,count:4096))+box("moov",moov(edit:nil))
        try data.write(to:file)
        XCTAssertEqual(check(try P4CadenceMOV.read(file)).status,.pass)
        XCTAssertEqual(try Data(contentsOf:file),data)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:folder.path),["synthetic.mov"])
    }
}
