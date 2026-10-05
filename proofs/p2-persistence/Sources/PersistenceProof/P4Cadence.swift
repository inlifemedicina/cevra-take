import Foundation

// Future short 30fps recordings only. Legacy fileProfile functions stay unchanged.
public struct P4CadenceSample: Equatable, Sendable {
    public let start: Int64, duration: Int64
    public init(start: Int64, duration: Int64) { self.start=start; self.duration=duration }
}
public struct P4CadenceTimeline: Sendable {
    public let scale: Int64, quantum: Int64, end: Int64
    public let samples: [P4CadenceSample]
    public init(scale: Int64, quantum: Int64, end: Int64, samples: [P4CadenceSample]) {
        self.scale=scale; self.quantum=quantum; self.end=end; self.samples=samples
    }
    public var seconds: Double { Double(end)/Double(scale) }
    public var report: [String:String] {
        ["timestampGridScale":String(scale),"timestampQuantumTicks":String(quantum),
         "timestampPresentedEndTicks":String(end),"timestampQuantumSeconds":String(Double(quantum)/Double(scale))]
    }
}
public enum P4CadenceStatus: String, Sendable { case pass="PASS", fail="FAIL", unavailable="NOT_VERIFIABLE" }
public struct P4CadenceResult: Equatable, Sendable {
    public static let version="P4-30FPS-CADENCE-002"
    public let status: P4CadenceStatus, reason: String
    public let averageFPS: Double?, samples: Int
    public init(_ status: P4CadenceStatus, _ reason: String, averageFPS: Double?=nil, samples: Int=0) {
        self.status=status; self.reason=reason; self.averageFPS=averageFPS; self.samples=samples
    }
    public var report: [String:String] {
        var result:[String:String]=["profileCriteriaVersion":Self.version,"timestampCadence":status.rawValue,
                    "timestampCadenceReason":reason,"presentedSamples":String(samples),
                    "timestampAverageFPS":averageFPS.map { String($0) } ?? "NOT_MEASURED"]
        result["sensorFrameLoss"]="NOT_MEASURED"; result["uniqueImageFrames"]="NOT_MEASURED"
        return result
    }
}
public enum P4Cadence {
    public static let maximumSamples=4096
    // Checked integer grid: no floating epsilon is used for cadence eligibility.
    public static func evaluate(_ timeline: P4CadenceTimeline?, configuredFPS: Int,
                                appliedFPS: Int?) -> P4CadenceResult {
        guard configuredFPS==30 else { return .init(.unavailable,"outside30fpsScope") }
        guard appliedFPS==30 else { return .init(.fail,"nativeApplied30Missing") }
        guard let t=timeline, t.scale>0, t.scale<=1_000_000_000,
              t.quantum>0, t.quantum<t.scale, t.scale%t.quantum==0, 60*t.quantum<t.scale,
              t.end>0, t.end<=64*t.scale,
              t.samples.count<=maximumSamples else { return .init(.unavailable,"timingUnavailable") }
        let bound=64*t.scale, budget=30*t.quantum
        guard t.samples.allSatisfy({ $0.start>=(-bound) && $0.start<=bound && $0.duration>0 && $0.duration<=bound }) else {
            return .init(.unavailable,"invalidSampleTiming")
        }
        // Retain actual intersections, including partial boundary samples after edits.
        let visible=t.samples.filter { $0.start<t.end && $0.start+$0.duration>0 }
        guard visible.count>=2 else { return .init(.unavailable,"tooFewPresentedSamples") }
        let first=visible[0].start, last=visible[visible.count-1].start
        let mean=last>first ? Double(visible.count-1)*Double(t.scale)/Double(last-first):nil
        func failure(_ reason: String) -> P4CadenceResult { .init(.fail,reason,averageFPS:mean,samples:visible.count) }
        var covered: Int64=0
        for (i,s) in visible.enumerated() {
            if i>0 {
                let delta=s.start-visible[i-1].start
                guard delta>0 else { return failure("nonMonotonicPTS") }
                guard abs(30*delta-t.scale)<=budget else { return failure("frameInterval") }
            }
            guard abs(30*(s.start-first)-Int64(i)*t.scale)<=budget else { return failure("accumulatedPhase") }
            let a=max(0,s.start), b=min(t.end,s.start+s.duration)
            guard 30*(b-a)<=t.scale+budget else { return failure("prolongedSample") }
            guard a-covered<=t.quantum else { return failure("uncoveredWindow") }
            covered=max(covered,b)
        }
        guard t.end-covered<=t.quantum else { return failure("uncoveredTail") }
        guard 30*(-first)<=t.scale+budget, first<=t.quantum else { return failure("initialBoundary") }
        guard 30*(t.end-last)<=t.scale+budget else { return failure("prolongedTail") }
        return .init(.pass,"oneTickContinuity",averageFPS:mean,samples:visible.count)
    }
}

// Bounded, metadata-only MOV reader. No decoder, media mutation, Store lock or sensor.
// A single rate-1 edit (or an unedited track) is supported; fragments/multiple edits
// and unavailable/malformed timing are NOT_VERIFIABLE, never guessed into PASS.
public enum P4CadenceMOV {
    public enum ReadError: Error { case unavailable, malformed, limit }
    private static let maximumMoov=2*1024*1024
    private struct Box { let type: String; let payload: Range<Int> }
    private struct Bytes {
        let bytes: [UInt8]
        func u(_ at: Int, _ count: Int) throws -> UInt64 {
            guard at>=0, count<=8, at<=bytes.count-count else { throw ReadError.malformed }
            return bytes[at..<at+count].reduce(UInt64(0)) { ($0<<8)|UInt64($1) }
        }
        func integer(_ at: Int, _ count: Int) throws -> Int64 {
            let value=try u(at,count); guard value<=Int64.max else { throw ReadError.limit }; return Int64(value)
        }
        func signed(_ at: Int, _ count: Int) throws -> Int64 {
            let value=try u(at,count)
            return count==8 ? Int64(bitPattern:value):Int64(Int32(bitPattern:UInt32(value)))
        }
        func boxes(_ range: Range<Int>) throws -> [Box] {
            var offset=range.lowerBound, result=[Box]()
            while offset<range.upperBound {
                guard result.count<128, range.upperBound-offset>=8 else { throw ReadError.limit }
                var size=try integer(offset,4), header=8
                let type=String(decoding:bytes[offset+4..<offset+8],as:UTF8.self)
                if size==1 { guard range.upperBound-offset>=16 else { throw ReadError.malformed };size=try integer(offset+8,8);header=16 }
                if size==0 { size=Int64(range.upperBound-offset) }
                guard size>=header, size<=range.upperBound-offset else { throw ReadError.malformed }
                result.append(Box(type:type,payload:offset+header..<offset+Int(size)));offset+=Int(size)
            }
            return result
        }
        func only(_ type: String, in boxes: [Box]) throws -> Box {
            let matches=boxes.filter { $0.type==type }
            guard matches.count==1 else { throw ReadError.unavailable };return matches[0]
        }
        func header(_ box: Box) throws -> (scale: Int64, duration: Int64) {
            let v=try u(box.payload.lowerBound,1)
            guard v<=1,box.payload.count>=(v==1 ? 32:20) else { throw ReadError.malformed }
            let at=box.payload.lowerBound+(v==1 ? 20:12), scale=try integer(at,4)
            guard scale>0,scale<=Int32.max else { throw ReadError.unavailable }
            return (scale,try integer(at+4,v==1 ? 8:4))
        }
    }
    private static func multiply(_ a: Int64, _ b: Int64) throws -> Int64 {
        let (v,overflow)=a.multipliedReportingOverflow(by:b);guard !overflow else { throw ReadError.limit };return v
    }
    private static func add(_ a: Int64, _ b: Int64) throws -> Int64 {
        let (v,overflow)=a.addingReportingOverflow(b);guard !overflow else { throw ReadError.limit };return v
    }
    public static func read(_ url: URL) throws -> P4CadenceTimeline {
        let file=try FileHandle(forReadingFrom:url);defer { try? file.close() }
        let length=try file.seekToEnd();var offset: UInt64=0, moov: Data?, count=0
        while offset<length {
            count+=1;guard count<=128,length-offset>=8 else { throw ReadError.limit }
            try file.seek(toOffset:offset)
            guard let head=try file.read(upToCount:8),head.count==8 else { throw ReadError.malformed }
            let h=Bytes(bytes:Array(head));var size=try h.u(0,4),header: UInt64=8
            if size==1 {
                guard let large=try file.read(upToCount:8),large.count==8 else { throw ReadError.malformed }
                size=try Bytes(bytes:Array(large)).u(0,8);header=16
            }
            if size==0 { size=length-offset }
            guard size>=header,size<=length-offset else { throw ReadError.malformed }
            let type=String(decoding:head[4..<8],as:UTF8.self)
            guard type != "moof" else { throw ReadError.unavailable }
            if type=="moov" {
                guard moov==nil,size-header<=maximumMoov else { throw ReadError.limit }
                guard let data=try file.read(upToCount:Int(size-header)),data.count==size-header else { throw ReadError.malformed }
                moov=data
            }
            offset+=size
        }
        guard let moov else { throw ReadError.unavailable }
        return try parse(moov:moov)
    }
    // Exposed for synthetic container fixtures; never substitutes for physical proof.
    public static func parse(moov: Data) throws -> P4CadenceTimeline {
        guard moov.count<=maximumMoov else { throw ReadError.limit }
        let b=Bytes(bytes:Array(moov)), root=try b.boxes(0..<moov.count)
        guard !root.contains(where: { $0.type=="mvex" }) else { throw ReadError.unavailable }
        let movie=try b.header(b.only("mvhd",in:root))
        let tracks=root.filter { $0.type=="trak" };guard tracks.count<=8 else { throw ReadError.limit }
        var videos=[([Box],[Box])]()
        for track in tracks {
            let children=try b.boxes(track.payload), mdia=try b.boxes(b.only("mdia",in:children).payload)
            let handler=try b.only("hdlr",in:mdia)
            guard handler.payload.count>=12 else { throw ReadError.malformed }
            let a=handler.payload.lowerBound+8
            if String(decoding:b.bytes[a..<a+4],as:UTF8.self)=="vide" { videos.append((children,mdia)) }
        }
        guard videos.count==1 else { throw ReadError.unavailable }
        let (track,mdia)=videos[0], media=try b.header(b.only("mdhd",in:mdia))
        let minf=try b.boxes(b.only("minf",in:mdia).payload), stbl=try b.boxes(b.only("stbl",in:minf).payload)
        let stts=try b.only("stts",in:stbl), stsz=try b.only("stsz",in:stbl)
        guard stts.payload.count>=8,stsz.payload.count>=12 else { throw ReadError.malformed }
        let sampleCount=try b.integer(stsz.payload.lowerBound+8,4)
        guard sampleCount>0,sampleCount<=P4Cadence.maximumSamples else { throw ReadError.limit }
        let sampleSize=try b.integer(stsz.payload.lowerBound+4,4)
        guard try b.u(stts.payload.lowerBound,1)==0,try b.u(stsz.payload.lowerBound,1)==0,
              stsz.payload.count==(sampleSize==0 ? 12+Int(sampleCount)*4:12) else { throw ReadError.malformed }
        let rows=try b.integer(stts.payload.lowerBound+4,4)
        guard rows>0,rows<=sampleCount,stts.payload.count==8+Int(rows)*8 else { throw ReadError.malformed }
        var starts=[Int64](), durations=[Int64](), elapsed: Int64=0
        for i in 0..<Int(rows) {
            let at=stts.payload.lowerBound+8+i*8,n=try b.integer(at,4),delta=try b.integer(at+4,4)
            guard n>0,n<=sampleCount-Int64(starts.count),delta>0 else { throw ReadError.malformed }
            for _ in 0..<Int(n) { starts.append(elapsed);durations.append(delta);elapsed=try add(elapsed,delta) }
        }
        guard starts.count==sampleCount,elapsed==media.duration else { throw ReadError.malformed }
        let composition=stbl.filter { $0.type=="ctts" };guard composition.count<=1 else { throw ReadError.malformed }
        if let box=composition.first {
            guard box.payload.count>=8 else { throw ReadError.malformed }
            let version=try b.u(box.payload.lowerBound,1),n=try b.integer(box.payload.lowerBound+4,4)
            guard version<=1,n>0,n<=sampleCount,box.payload.count==8+Int(n)*8 else { throw ReadError.malformed }
            var index=0
            for i in 0..<Int(n) {
                let at=box.payload.lowerBound+8+i*8,count=try b.integer(at,4)
                let shift=try version==0 ? b.integer(at+4,4):b.signed(at+4,4)
                guard count>0,count<=sampleCount-Int64(index) else { throw ReadError.malformed }
                for _ in 0..<Int(count) { starts[index]=try add(starts[index],shift);index+=1 }
            }
            guard index==starts.count else { throw ReadError.malformed }
        }
        var sourceStart: Int64=0, editDuration=media.duration, editScale=media.scale
        let edits=track.filter { $0.type=="edts" };guard edits.count<=1 else { throw ReadError.malformed }
        if let edts=edits.first {
            let edit=try b.only("elst",in:b.boxes(edts.payload)),at=edit.payload.lowerBound
            guard edit.payload.count>=8 else { throw ReadError.malformed }
            let version=try b.u(at,1),count=try b.integer(at+4,4)
            guard version<=1,count==1,edit.payload.count==(version==1 ? 28:20) else { throw ReadError.unavailable }
            editDuration=try b.integer(at+8,version==1 ? 8:4)
            sourceStart=try b.signed(at+(version==1 ? 16:12),version==1 ? 8:4)
            let rateAt=at+(version==1 ? 24:16)
            guard sourceStart>=0,try b.u(rateAt,2)==1,try b.u(rateAt+2,2)==0 else { throw ReadError.unavailable }
            editScale=movie.scale
        }
        func gcd(_ x: Int64,_ y: Int64) -> Int64 { var a=x,b=y;while b != 0 { (a,b)=(b,a%b) };return a }
        let grid=try multiply(media.scale/gcd(media.scale,editScale),editScale)
        guard grid<=1_000_000_000 else { throw ReadError.limit }
        let factor=grid/media.scale,quantum=factor,end=try multiply(editDuration,grid/editScale)
        let sourceOffset=try multiply(sourceStart,factor)
        guard sourceOffset<Int64.max else { throw ReadError.limit }
        var samples=[P4CadenceSample]()
        for i in starts.indices {
            let scaled=try multiply(starts[i],factor)
            let start=try add(scaled,-sourceOffset),duration=try multiply(durations[i],factor)
            samples.append(.init(start:start,duration:duration))
        }
        samples.sort { $0.start<$1.start }
        return .init(scale:grid,quantum:quantum,end:end,samples:samples)
    }
}
